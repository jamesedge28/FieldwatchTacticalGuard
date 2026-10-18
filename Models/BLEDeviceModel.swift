import Foundation
import CoreBluetooth

/// Clasificación de Inteligencia de Señales Radiofrecuencia
public enum BLEDeviceCategory: String, CaseIterable, Codable {
    case suspiciousTransmitter = "TRANSMISOR SOSPECHOSO"
    case surveillanceBeacon = "BALIZA / RASTREADOR"
    case audioVideoLink = "ENLACE AV INALÁMBRICO"
    case genericPeripheral = "DISPOSITIVO BLE ESTÁNDAR"
    case unknown = "OBJETO NO IDENTIFICADO"

    public var badgeColorHex: String {
        switch self {
        case .suspiciousTransmitter: return "#FF3B30" // Rojo Alerta
        case .surveillanceBeacon: return "#FF9500"    // Ámbar Advertencia
        case .audioVideoLink: return "#00E5FF"        // Cian HUD
        case .genericPeripheral: return "#00FF00"     // Verde Táctico
        case .unknown: return "#8E8E93"               // Gris
        }
    }
}

/// Modelo de Dispositivo BLE detectado por el escáner táctico pasivo
public struct BLEDeviceModel: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public var rssi: Int
    public var previousRssi: Int?
    public let txPower: Int?
    public let serviceUUIDs: [String]
    public let isConnectable: Bool
    public var lastSeen: Date
    public var category: BLEDeviceCategory

    public init(id: UUID,
                name: String?,
                rssi: Int,
                txPower: Int? = nil,
                serviceUUIDs: [String] = [],
                isConnectable: Bool = true,
                lastSeen: Date = Date(),
                category: BLEDeviceCategory? = nil) {
        self.id = id
        self.name = (name?.isEmpty ?? true) ? "NODO_OCULTO_\(id.uuidString.prefix(6))" : name!
        self.rssi = rssi
        self.previousRssi = nil
        self.txPower = txPower
        self.serviceUUIDs = serviceUUIDs
        self.isConnectable = isConnectable
        self.lastSeen = lastSeen
        self.category = category ?? BLEDeviceModel.classifyDevice(name: name, serviceUUIDs: serviceUUIDs, rssi: rssi)
    }

    /// Normaliza el RSSI a un rango entre 0.0 (señal nula: -100 dBm) y 1.0 (señal máxima: -30 dBm)
    public var normalizedSignal: Double {
        let clamped = max(-100, min(-30, rssi))
        return Double(clamped - (-100)) / Double(-30 - (-100))
    }

    /// Estimación física de distancia en metros usando modelo logarítmico de pérdidas de trayectoria
    /// Formula: d = 10 ^ ((TxPower - RSSI) / (10 * n)) donde n = 2.4 en interiores típicos
    public var estimatedDistanceMeters: Double {
        let measuredPower = txPower ?? -59
        let pathLossExponent = 2.4
        let exponent = Double(measuredPower - rssi) / (10.0 * pathLossExponent)
        let distance = pow(10.0, exponent)
        return min(50.0, max(0.05, distance))
    }

    /// Clasificación heurística de contrainteligencia táctica
    public static func classifyDevice(name: String?, serviceUUIDs: [String], rssi: Int) -> BLEDeviceCategory {
        let cleanName = (name ?? "").lowercased()

        // Patrones sospechosos de cámaras espía o transmisores encubiertos
        let spyKeywords = ["cam", "spy", "dvr", "nvr", "micro", "stream", "video", "fpv", "hid", "lens", "rec"]
        for key in spyKeywords {
            if cleanName.contains(key) {
                return .suspiciousTransmitter
            }
        }

        // Balizas y rastreadores de geolocalización (AirTags, Tile, Chipolo)
        let trackerKeywords = ["airtag", "smarttag", "tile", "beacon", "itag", "finder", "tracker"]
        for key in trackerKeywords {
            if cleanName.contains(key) {
                return .surveillanceBeacon
            }
        }

        // Enlaces de audio/auriculares encubiertos
        let audioKeywords = ["audio", "mic", "ear", "voice", "sound", "headset"]
        for key in audioKeywords {
            if cleanName.contains(key) {
                return .audioVideoLink
            }
        }

        // Si transmite con alta potencia muy cercana (< -45 dBm) sin nombre visible
        if (name == nil || name!.isEmpty) && rssi > -45 {
            return .suspiciousTransmitter
        }

        if name == nil || name!.isEmpty {
            return .unknown
        }

        return .genericPeripheral
    }
}
