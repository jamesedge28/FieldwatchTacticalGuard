import Foundation
import CoreGraphics

/// Tipo de Micro-Anomalía en la Superficie
public enum SurfaceAnomalyType: String {
    case contactMicrophoneIndent = "HUNDIMIENTO / MICRÓFONO DE CONTACTO"
    case lockDrillingOrBypass = "TALADRADO O FORZADO DE CERRADURA"
    case freshPaintPatch = "PARCHE DE PINTURA RECIENTE / RELLENO"
    case nominalSurface = "SUPERFICIE ÍNTEGRA / SIN ALTERACIONES"
}

/// Punto de muestra de microrrelieve de la superficie
public struct SurfaceMicroPoint: Identifiable, Equatable {
    public let id: String
    public let xNorm: Double // 0.0 a 1.0 en el eje de la superficie
    public let yNorm: Double // 0.0 a 1.0
    public var baselineHeightMM: Double
    public var auditHeightMM: Double

    public var deltaMM: Double {
        return auditHeightMM - baselineHeightMM
    }

    public var anomalyType: SurfaceAnomalyType {
        let absDelta = abs(deltaMM)
        if absDelta < 0.25 {
            return .nominalSurface
        } else if deltaMM > 0.8 {
            return .freshPaintPatch
        } else if deltaMM < -0.8 {
            return .lockDrillingOrBypass
        } else {
            return .contactMicrophoneIndent
        }
    }
}

/// Perfil de Auditoría de Alta Precisión de una Superficie Crítica (Cerradura, Caja Fuerte, Pared)
public struct SurfaceAuditProfile: Identifiable {
    public let id = UUID()
    public let surfaceName: String
    public let targetType: String // Cerradura, Caja Fuerte, Pared de yeso, Marco de ventana
    public let captureDate: Date
    public var auditDate: Date?
    public var points: [SurfaceMicroPoint]
    public var isAudited: Bool

    public init(surfaceName: String, targetType: String, points: [SurfaceMicroPoint] = [], isAudited: Bool = false) {
        self.surfaceName = surfaceName
        self.targetType = targetType
        self.captureDate = Date()
        self.auditDate = isAudited ? Date() : nil
        self.points = points
        self.isAudited = isAudited
    }

    /// Máxima variación de micro-relieve registrada en milímetros
    public var maxDeviationMM: Double {
        points.map { abs($0.deltaMM) }.max() ?? 0.0
    }

    /// Cantidad de puntos que superan el umbral de alerta (0.5 mm)
    public var compromisedPointsCount: Int {
        points.filter { abs($0.deltaMM) >= 0.5 }.count
    }

    /// Porcentaje de integridad de la superficie
    public var integrityScorePercent: Double {
        guard !points.isEmpty else { return 100.0 }
        let cleanPoints = points.filter { abs($0.deltaMM) < 0.4 }.count
        return (Double(cleanPoints) / Double(points.count)) * 100.0
    }
}
