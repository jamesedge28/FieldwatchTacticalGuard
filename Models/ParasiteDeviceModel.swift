import Foundation

/// Estado de Evaluación de Seguridad Física
public enum ParasiteRiskLevel: String, Codable {
    case nominal = "CONFORME / ESTÁNDAR"
    case suspicious = "SOSPECHOSO (DESVIACIÓN VOLUMÉTRICA)"
    case criticalParasite = "CRÍTICO: MODIFICACIÓN O DISPOSITIVO PARÁSITO"
}

/// Especificación de Fábrica de Componente Eléctrico Estándar
public struct FactoryHardwareProfile: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let category: String
    public let standardWidthMM: Double   // Ancho (mm)
    public let standardHeightMM: Double  // Alto (mm)
    public let standardDepthMM: Double   // Profundidad (mm)
    public let standardVolumeCm3: Double // Volumen nominal (cm^3)
    public let tolerancePercent: Double  // Tolerancia admisible (+/- %)
    public let commonSpyVulnerability: String // Vector común de espionaje

    public init(id: String,
                name: String,
                category: String,
                width: Double,
                height: Double,
                depth: Double,
                tolerance: Double = 5.0,
                vulnerability: String) {
        self.id = id
        self.name = name
        self.category = category
        self.standardWidthMM = width
        self.standardHeightMM = height
        self.standardDepthMM = depth
        self.standardVolumeCm3 = (width * height * depth) / 1000.0
        self.tolerancePercent = tolerance
        self.commonSpyVulnerability = vulnerability
    }
}

/// Medición Escaneada con LiDAR y Evaluación Comparativa
public struct ScannedHardwareAudit: Identifiable {
    public let id = UUID()
    public let profile: FactoryHardwareProfile
    public var measuredWidthMM: Double
    public var measuredHeightMM: Double
    public var measuredDepthMM: Double
    public var timestamp: Date

    public init(profile: FactoryHardwareProfile,
                measuredWidth: Double,
                measuredHeight: Double,
                measuredDepth: Double,
                timestamp: Date = Date()) {
        self.profile = profile
        self.measuredWidthMM = measuredWidth
        self.measuredHeightMM = measuredHeight
        self.measuredDepthMM = measuredDepth
        self.timestamp = timestamp
    }

    public var measuredVolumeCm3: Double {
        return (measuredWidthMM * measuredHeightMM * measuredDepthMM) / 1000.0
    }

    public var volumeDeltaPercent: Double {
        guard profile.standardVolumeCm3 > 0 else { return 0 }
        return ((measuredVolumeCm3 - profile.standardVolumeCm3) / profile.standardVolumeCm3) * 100.0
    }

    public var widthDeltaMM: Double {
        return measuredWidthMM - profile.standardWidthMM
    }

    public var heightDeltaMM: Double {
        return measuredHeightMM - profile.standardHeightMM
    }

    public var depthDeltaMM: Double {
        return measuredDepthMM - profile.standardDepthMM
    }

    public var riskLevel: ParasiteRiskLevel {
        let absVolumeDelta = abs(volumeDeltaPercent)
        if absVolumeDelta > (profile.tolerancePercent * 2.5) || volumeDeltaPercent > 12.0 {
            return .criticalParasite
        } else if absVolumeDelta > profile.tolerancePercent {
            return .suspicious
        } else {
            return .nominal
        }
    }
}

/// Catálogo Mock de Fábrica de Dispositivos Comunes
public struct HardwareCatalogDatabase {
    public static let standardProfiles: [FactoryHardwareProfile] = [
        FactoryHardwareProfile(
            id: "HW_CHG_APPLE_20W",
            name: "Cargador USB-C 20W Estándar",
            category: "Adaptadores de Pared",
            width: 41.5,
            height: 42.5,
            depth: 27.5,
            tolerance: 4.0,
            vulnerability: "Cámara pinhole en orificio falso o transmisor Wi-Fi 2.4GHz en carcasa sobredimensionada."
        ),
        FactoryHardwareProfile(
            id: "HW_CHG_ANKER_NANO",
            name: "Adaptador GaN Compacto 30W",
            category: "Adaptadores de Pared",
            width: 28.5,
            height: 28.5,
            depth: 35.5,
            tolerance: 4.0,
            vulnerability: "Micro-micrófono GSM/SIM oculta en el chasis posterior."
        ),
        FactoryHardwareProfile(
            id: "HW_SMOKE_COMMERCIAL",
            name: "Detector de Humo Techo Fotoeléctrico",
            category: "Detectores y Sensores",
            width: 120.0,
            height: 120.0,
            depth: 42.0,
            tolerance: 6.0,
            vulnerability: "Lente cónico gran angular oculto detrás de la rejilla de ventilación."
        ),
        FactoryHardwareProfile(
            id: "HW_POWER_STRIP_US",
            name: "Regleta Multicontacto 4 Tomas",
            category: "Distribución Eléctrica",
            width: 245.0,
            height: 52.0,
            depth: 38.0,
            tolerance: 5.0,
            vulnerability: "Módulo espía parásito conectado a los 110V/220V con antena interna."
        ),
        FactoryHardwareProfile(
            id: "HW_WALL_OUTLET_FACEPLATE",
            name: "Placa Frontal de Enchufe Doble",
            category: "Instalación de Pared",
            width: 70.0,
            height: 115.0,
            depth: 6.5,
            tolerance: 3.0,
            vulnerability: "Micro-cámara en el tornillo de sujeción central perforado."
        )
    ]
}
