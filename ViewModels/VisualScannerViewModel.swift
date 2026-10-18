import Foundation
import AVFoundation
import CoreImage
import UIKit
import Combine

/// ViewModel para la gestión de la cámara trasera con AVFoundation y filtrado óptico infrarrojo
public final class VisualScannerViewModel: NSObject, ObservableObject {
    // MARK: - Estado Publicado
    @Published public var isRunning: Bool = false
    @Published public var isAuthorized: Bool = false
    @Published public var detectedInfraredHotspots: [CGPoint] = []
    @Published public var irThreshold: Double = 0.85          // Umbral de brillo de corte (0.0 a 1.0)
    @Published public var exposureBoost: Double = 2.0         // Factor de exposición para destellos IR
    @Published public var filterMode: OpticalFilterMode = .infraredHighlight
    @Published public var currentFPS: Double = 30.0
    @Published public var opticalAnomalyDetected: Bool = false

    // MARK: - Modos de Filtrado Óptico
    public enum OpticalFilterMode: String, CaseIterable {
        case infraredHighlight = "FILTRO IR (SUPRESIÓN CROMÁTICA)"
        case extremeContrast = "ALTO CONTRASTE TÁCTICO"
        case invertedNightVision = "NEGATIVO ÓPTICO FORENSE"
    }

    // MARK: - Propiedades de AVFoundation y CoreImage
    public let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.fieldwatch.tactical.cameraQueue")
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    // Callback para pasar la imagen procesada a la vista SwiftUI
    public var onFrameProcessed: ((UIImage) -> Void)?

    public override init() {
        super.init()
        checkPermissions()
    }

    // MARK: - Permisos y Configuración

    public func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.isAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        default:
            self.isAuthorized = false
        }
    }

    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                print("[CÁMARA] Error: Cámara trasera no disponible.")
                self.captureSession.commitConfiguration()
                return
            }

            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }

            self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]

            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }

            self.captureSession.commitConfiguration()
        }
    }

    public func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.isRunning = true
            }
        }
    }

    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }

    // MARK: - Algoritmo de Supresión Cromática y Resaltado de LEDs Infrarrojos

    /// Aplica una cadena de filtros CIFilter para suprimir todos los colores ambientales
    /// y forzar que la radiación infrarroja cercana (captada por el sensor CMOS como un blanco violáceo intenso)
    /// se exponga como un punto blanco puro de máxima luminancia (#FFFFFF) sobre un fondo negro profundo (#000000).
    private func processImageBuffer(pixelBuffer: CVPixelBuffer) -> UIImage? {
        let rawCIImage = CIImage(cvPixelBuffer: pixelBuffer)

        // 1. Desaturación completa y maximización de contraste (Escala de grises táctica)
        guard let desaturateFilter = CIFilter(name: "CIColorControls") else { return nil }
        desaturateFilter.setValue(rawCIImage, forKey: kCIInputImageKey)
        desaturateFilter.setValue(0.0, forKey: kCIInputSaturationKey) // Cero color ambiental
        desaturateFilter.setValue(1.8, forKey: kCIInputContrastKey)   // Alto contraste

        guard let desaturatedImage = desaturateFilter.outputImage else { return nil }

        // 2. Ajuste de exposición extremo para suprimir tonos oscuros/medios y aislar picos luminosos
        guard let exposureFilter = CIFilter(name: "CIExposureAdjust") else { return nil }
        exposureFilter.setValue(desaturatedImage, forKey: kCIInputImageKey)
        exposureFilter.setValue(-1.5 + (exposureBoost * 0.5), forKey: kCIInputEVKey)

        guard let exposedImage = exposureFilter.outputImage else { return nil }

        // 3. Matriz de Umbralización y Máscara de Detección de Destellos IR
        let finalImage: CIImage
        switch filterMode {
        case .infraredHighlight:
            // Eleva al cuadrado los valores altos para que solo sobrevivan los destellos IR directos
            guard let gammaFilter = CIFilter(name: "CIGammaAdjust") else { return nil }
            gammaFilter.setValue(exposedImage, forKey: kCIInputImageKey)
            gammaFilter.setValue(3.2, forKey: "inputPower")
            finalImage = gammaFilter.outputImage ?? exposedImage

        case .extremeContrast:
            guard let posterize = CIFilter(name: "CIColorPosterize") else { return nil }
            posterize.setValue(exposedImage, forKey: kCIInputImageKey)
            posterize.setValue(3.0, forKey: "inputLevels")
            finalImage = posterize.outputImage ?? exposedImage

        case .invertedNightVision:
            guard let invertFilter = CIFilter(name: "CIColorInvert") else { return nil }
            invertFilter.setValue(exposedImage, forKey: kCIInputImageKey)
            finalImage = invertFilter.outputImage ?? exposedImage
        }

        // Renderizado a UIImage
        if let cgImage = ciContext.createCGImage(finalImage, from: finalImage.extent) {
            return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
        }

        return nil
    }

    /// Análisis de luminancia rápida para detectar coordenadas de puntos brillantes sospechosos
    private func detectHotspots(in pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        var brightPoints: [CGPoint] = []
        let thresholdValue = UInt8(min(255, max(180, Int(irThreshold * 255.0))))
        let step = 32 // Muestreo en cuadrícula para mantener 30+ FPS

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let offset = y * bytesPerRow + x * 4
                let blue = buffer[offset]
                let green = buffer[offset + 1]
                let red = buffer[offset + 2]

                // El destello IR sobresatura los 3 canales casi al máximo
                if red > thresholdValue && green > thresholdValue && blue > thresholdValue {
                    let normX = CGFloat(x) / CGFloat(width)
                    let normY = CGFloat(y) / CGFloat(height)
                    brightPoints.append(CGPoint(x: normX, y: normY))
                }
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.detectedInfraredHotspots = Array(brightPoints.prefix(4))
            self.opticalAnomalyDetected = !brightPoints.isEmpty

            if self.opticalAnomalyDetected {
                AudioHapticEngine.shared.triggerRadarPulse()
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension VisualScannerViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Detección de puntos calientes en subproceso
        detectHotspots(in: pixelBuffer)

        // Generar fotograma procesado
        if let processedImage = processImageBuffer(pixelBuffer: pixelBuffer) {
            DispatchQueue.main.async {
                self.onFrameProcessed?(processedImage)
            }
        }
    }
}
