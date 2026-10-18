import Foundation
import Combine
import SwiftUI

/// Modo de Operación en el Módulo de Integridad Física
public enum PhysicalIntegrityMode: String, CaseIterable {
    case surfaceAudit = "MICRO-RELIEVES (CERRADURAS/PAREDES)"
    case parasiteCatalog = "DISPOSITIVOS PARÁSITOS (HARDWARE ESPÍA)"
}

/// ViewModel para la auditoría de superficies sub-milimétricas y análisis volumétrico de hardware parásito
public final class PhysicalIntegrityViewModel: ObservableObject {
    // MARK: - Estado Publicado
    @Published public var selectedMode: PhysicalIntegrityMode = .surfaceAudit

    // Submódulo 1: Alteraciones en Paredes y Cerraduras
    @Published public var currentSurfaceProfile: SurfaceAuditProfile
    @Published public var isAuditModeActive: Bool = false
    @Published public var selectedSurfaceTarget: String = "CERRADURA_PRINCIPAL_DORADO"
    @Published public var detectedAlterationsCount: Int = 0
    @Published public var isScanningSurface: Bool = false

    // Submódulo 2: Dispositivos Parásitos
    @Published public var factoryProfiles: [FactoryHardwareProfile] = HardwareCatalogDatabase.standardProfiles
    @Published public var selectedFactoryProfile: FactoryHardwareProfile = HardwareCatalogDatabase.standardProfiles[0]
    @Published public var scannedWidthMM: Double = 41.5
    @Published public var scannedHeightMM: Double = 42.5
    @Published public var scannedDepthMM: Double = 27.5
    @Published public var activeAudit: ScannedHardwareAudit?
    @Published public var auditHistory: [ScannedHardwareAudit] = []

    public init() {
        // Inicializar perfil base de superficie
        self.currentSurfaceProfile = SurfaceAuditProfile(
            surfaceName: "Cerradura Cilindro Seguridad",
            targetType: "Cerradura de Puerta",
            points: PhysicalIntegrityViewModel.generateSurfacePoints(withAlteration: false),
            isAudited: false
        )
        evaluateCurrentHardwareAudit()
    }

    // MARK: - Submódulo: Auditoría de Microrrelieves en Cerraduras y Paredes

    /// Genera la cuadrícula de relieve de alta resolución
    public static func generateSurfacePoints(withAlteration: Bool) -> [SurfaceMicroPoint] {
        var points: [SurfaceMicroPoint] = []
        let gridSize = 10

        for y in 0..<gridSize {
            for x in 0..<gridSize {
                let normX = Double(x) / Double(gridSize - 1)
                let normY = Double(y) / Double(gridSize - 1)

                // Superficie nominal con micro-rugosidad de fábrica de 0.05mm
                let baselineH = 0.0 + Double.random(in: -0.05...0.05)
                var auditH = baselineH

                // Si se activa una alteración simulada (ej. manipulación de cerradura o micrófono de contacto)
                if withAlteration {
                    // Simular hundimiento en el centro (x=5, y=5) por micrófono o parche de pintura
                    if (x == 4 || x == 5) && (y == 4 || y == 5) {
                        auditH = baselineH - 1.25 // Hundimiento de 1.25 mm (supera el umbral de 1 mm)
                    } else if x == 7 && y == 2 {
                        auditH = baselineH + 0.95 // Parche de masilla/pintura reciente (+0.95 mm)
                    }
                }

                points.append(SurfaceMicroPoint(
                    id: "PT_\(x)_\(y)",
                    xNorm: normX,
                    yNorm: normY,
                    baselineHeightMM: baselineH,
                    auditHeightMM: auditH
                ))
            }
        }
        return points
    }

    /// Captura el perfil inicial (baseline) de la cerradura o pared
    public func captureBaselineSurface() {
        self.isScanningSurface = true
        AudioHapticEngine.shared.triggerRadarPulse()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.currentSurfaceProfile = SurfaceAuditProfile(
                surfaceName: self.selectedSurfaceTarget,
                targetType: "Superficie de Alta Seguridad",
                points: PhysicalIntegrityViewModel.generateSurfacePoints(withAlteration: false),
                isAudited: false
            )
            self.isAuditModeActive = false
            self.isScanningSurface = false
            self.detectedAlterationsCount = 0
            AudioHapticEngine.shared.triggerSuccessHaptic()
        }
    }

    /// Ejecuta la segunda pasada ("Modo Auditoría") y calcula desviaciones sub-milimétricas
    public func performAuditComparison(simulateTampering: Bool = true) {
        self.isScanningSurface = true
        AudioHapticEngine.shared.triggerRadarPulse()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self else { return }
            let auditedPoints = PhysicalIntegrityViewModel.generateSurfacePoints(withAlteration: simulateTampering)
            self.currentSurfaceProfile = SurfaceAuditProfile(
                surfaceName: self.selectedSurfaceTarget,
                targetType: "Superficie de Alta Seguridad",
                points: auditedPoints,
                isAudited: true
            )
            self.isAuditModeActive = true
            self.isScanningSurface = false
            self.detectedAlterationsCount = self.currentSurfaceProfile.compromisedPointsCount

            if self.detectedAlterationsCount > 0 {
                AudioHapticEngine.shared.playTacticalSiren(cycles: 2)
                AudioHapticEngine.shared.triggerIntrusionAlertHaptics()
            } else {
                AudioHapticEngine.shared.triggerSuccessHaptic()
            }
        }
    }

    // MARK: - Submódulo: Dispositivos Parásitos (Cotejo Volumétrico)

    public func selectFactoryProfile(_ profile: FactoryHardwareProfile) {
        self.selectedFactoryProfile = profile
        // Resetear medidas escaneadas al valor nominal
        self.scannedWidthMM = profile.standardWidthMM
        self.scannedHeightMM = profile.standardHeightMM
        self.scannedDepthMM = profile.standardDepthMM
        evaluateCurrentHardwareAudit()
    }

    /// Recalcula la auditoría volumétrica en base a los datos del calibrador LiDAR
    public func evaluateCurrentHardwareAudit() {
        let audit = ScannedHardwareAudit(
            profile: selectedFactoryProfile,
            measuredWidth: scannedWidthMM,
            measuredHeight: scannedHeightMM,
            measuredDepth: scannedDepthMM
        )
        self.activeAudit = audit
    }

    /// Simula la detección de un cargador parásito con cámara oculta (volumen +22%)
    public func applySpyParasiteSimulation() {
        // Un cargador con cámara suele ser 5mm más profundo y 3mm más ancho para alojar la PCB espía
        self.scannedWidthMM = selectedFactoryProfile.standardWidthMM + 3.8
        self.scannedHeightMM = selectedFactoryProfile.standardHeightMM + 2.5
        self.scannedDepthMM = selectedFactoryProfile.standardDepthMM + 6.2
        evaluateCurrentHardwareAudit()

        AudioHapticEngine.shared.playTacticalSiren(cycles: 2)
        AudioHapticEngine.shared.triggerIntrusionAlertHaptics()
    }

    /// Guarda la auditoría actual en el historial de inspección física
    public func saveCurrentAuditToHistory() {
        guard let audit = activeAudit else { return }
        self.auditHistory.insert(audit, at: 0)
        AudioHapticEngine.shared.triggerSuccessHaptic()
    }
}
