import Foundation

/// Estado del Sistema Centinela
public enum SentinelState: Equatable {
    case disarmed
    case arming(secondsRemaining: Int)
    case armed
    case alarmTriggered(maxDeltaCm: Double, triggerTime: Date)

    public var statusDescription: String {
        switch self {
        case .disarmed:
            return "DESARMADO // ESPERA DE ORDEN"
        case .arming(let sec):
            return "ARMANDO SISTEMA: T-\(sec)s (DESPEJE EL ÁREA)"
        case .armed:
            return "CENTINELA ACTIVO // MONITOREO VOLUMÉTRICO EN OSCURIDAD"
        case .alarmTriggered(let delta, _):
            return "¡ALERTA DE INTRUSIÓN! VARIACIÓN: \(String(format: "%.1f", delta)) CM"
        }
    }
}

/// Registro de Incidente de Intrusión Centinela
public struct SentinelIntrusionLog: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let sector: String
    public let deltaDisplacementCm: Double
    public let durationSeconds: Double

    public init(timestamp: Date = Date(), sector: String, deltaDisplacementCm: Double, durationSeconds: Double = 0.0) {
        self.timestamp = timestamp
        self.sector = sector
        self.deltaDisplacementCm = deltaDisplacementCm
        self.durationSeconds = durationSeconds
    }
}

/// Snapshot Geométrico 3D de Referencia del LiDAR
public struct SentinelDepthSnapshot {
    public let id = UUID()
    public let timestamp: Date
    public let sectorName: String
    public let depthMatrix: [[Float]] // Matriz M x N de distancias en metros
    public let averageDistanceMeters: Float
    public let gridResolution: Int

    public init(sectorName: String, depthMatrix: [[Float]], gridResolution: Int = 16) {
        self.timestamp = Date()
        self.sectorName = sectorName
        self.depthMatrix = depthMatrix
        self.gridResolution = gridResolution

        // Calcular distancia promedio
        var sum: Float = 0
        var count: Float = 0
        for row in depthMatrix {
            for val in row where val > 0.1 && val < 10.0 {
                sum += val
                count += 1
            }
        }
        self.averageDistanceMeters = count > 0 ? (sum / count) : 2.0
    }
}
