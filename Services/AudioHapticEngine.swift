import Foundation
import AVFoundation
import UIKit

/// Motor de Audio Sintetizado y Hápticos Tácticos
/// Genera alertas de audio militar, pulsos acústicos y patrones hápticos de alta vibración sin dependencias externas.
public final class AudioHapticEngine {
    public static let shared = AudioHapticEngine()

    private var audioEngine: AVAudioEngine?
    private var isEngineRunning = false
    private let hapticImpactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let hapticNotification = UINotificationFeedbackGenerator()
    private let hapticRigid = UIImpactFeedbackGenerator(style: .rigid)

    private init() {
        setupAudioSession()
        prepareHaptics()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        } catch {
            print("[AUDIO] Error configurando sesión de audio: \(error.localizedDescription)")
        }
    }

    private func prepareHaptics() {
        hapticImpactHeavy.prepare()
        hapticNotification.prepare()
        hapticRigid.prepare()
    }

    // MARK: - Efectos Hápticos

    /// Disparo de vibración táctica estándar de confirmación de radar
    public func triggerRadarPulse() {
        DispatchQueue.main.async {
            self.hapticRigid.impactOccurred(intensity: 0.7)
        }
    }

    /// Alerta háptica extrema para intrusión volumétrica (Centinela) o anomalía láser
    public func triggerIntrusionAlertHaptics() {
        DispatchQueue.main.async {
            self.hapticNotification.notificationOccurred(.error)
            self.hapticImpactHeavy.impactOccurred(intensity: 1.0)
        }
    }

    public func triggerSuccessHaptic() {
        DispatchQueue.main.async {
            self.hapticNotification.notificationOccurred(.success)
        }
    }

    public func triggerWarningHaptic() {
        DispatchQueue.main.async {
            self.hapticNotification.notificationOccurred(.warning)
        }
    }

    // MARK: - Generación de Tonos Sintetizados

    /// Sintetiza un tono acústico senoidal en una frecuencia y duración dadas
    public func playTone(frequency: Double, duration: Double, volume: Float = 0.8) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let engine = AVAudioEngine()
            let mainMixer = engine.mainMixerNode
            let sampleRate = mainMixer.outputFormat(forBus: 0).sampleRate
            guard sampleRate > 0 else { return }

            let frameCount = AVAudioFrameCount(sampleRate * duration)
            guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
                  let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                return
            }

            buffer.frameLength = frameCount
            let channels = buffer.floatChannelData
            guard let channelData = channels?[0] else { return }

            let angularFrequency = 2.0 * Double.pi * frequency / sampleRate
            for frame in 0..<Int(frameCount) {
                // Generador senoidal con desvanecimiento de borde para evitar 'clicks'
                let progress = Double(frame) / Double(frameCount)
                let envelope: Double
                if progress < 0.1 {
                    envelope = progress / 0.1
                } else if progress > 0.9 {
                    envelope = (1.0 - progress) / 0.1
                } else {
                    envelope = 1.0
                }
                channelData[frame] = Float(sin(angularFrequency * Double(frame)) * envelope * Double(volume))
            }

            let playerNode = AVAudioPlayerNode()
            engine.attach(playerNode)
            engine.connect(playerNode, to: mainMixer, format: format)

            do {
                try engine.start()
                playerNode.play()
                playerNode.scheduleBuffer(buffer, at: nil, options: []) {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                        playerNode.stop()
                        engine.stop()
                    }
                }
            } catch {
                print("[AUDIO] Error iniciando tono de alerta: \(error)")
            }
        }
    }

    /// Alarma acústica táctica dual militar (Alternancia 880Hz - 1760Hz)
    public func playTacticalSiren(cycles: Int = 3) {
        for i in 0..<cycles {
            DispatchQueue.global().asyncAfter(deadline: .now() + Double(i) * 0.35) {
                self.playTone(frequency: 1800, duration: 0.15, volume: 1.0)
                self.triggerIntrusionAlertHaptics()
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + Double(i) * 0.35 + 0.18) {
                self.playTone(frequency: 900, duration: 0.15, volume: 0.9)
            }
        }
    }

    /// Sonido de radar o "Geiger click" para proximidad RF
    public func playRFGeigerClick(rssiIntensity: Double) {
        // Cuanto más cerca (rssi más cercano a 0), frecuencia más aguda
        let freq = 1200.0 + (rssiIntensity * 1500.0)
        playTone(frequency: freq, duration: 0.04, volume: 0.5)
        triggerRadarPulse()
    }
}
