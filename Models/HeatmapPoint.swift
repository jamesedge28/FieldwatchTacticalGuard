import Foundation
import CoreGraphics

/// Estado de Seguridad en la Zona del Mapa Térmico
public enum TacticalZoneType: String {
    case safeBlindSpot = "PUNTO CIEGO SEGURO"        // Señal atenuada / blindaje natural
    case neutralZone = "ZONA NEUTRAL / AMBIENTAL"    // Ruido de fondo normal
    case criticalTransmitter = "ORIGEN SOSPECHOSO"   // Pico máximo de radiación (posible cámara/transmisor)
}

/// Punto de muestra en el retículo del mapa térmico RF
public struct HeatmapGridCell: Identifiable, Equatable {
    public let id: String
    public let row: Int
    public let col: Int
    public var signalIntensity: Double // 0.0 (silencio total) a 1.0 (máxima potencia RF)
    public var rssiDbm: Int
    public var isTransmitterPeak: Bool
    public var isSafeZone: Bool

    public init(row: Int, col: Int, signalIntensity: Double, rssiDbm: Int = -95, isTransmitterPeak: Bool = false, isSafeZone: Bool = false) {
        self.id = "CELL_\(row)_\(col)"
        self.row = row
        self.col = col
        self.signalIntensity = max(0.0, min(1.0, signalIntensity))
        self.rssiDbm = rssiDbm
        self.isTransmitterPeak = isTransmitterPeak
        self.isSafeZone = isSafeZone
    }

    public var zoneType: TacticalZoneType {
        if isTransmitterPeak {
            return .criticalTransmitter
        } else if isSafeZone || signalIntensity < 0.25 {
            return .safeBlindSpot
        } else {
            return .neutralZone
        }
    }
}

/// Malla espacial 2D/3D simulada para geolocalizar puntos ciegos y antenas espía
public struct HeatmapGridData {
    public let rows: Int
    public let cols: Int
    public var cells: [HeatmapGridCell]
    public var estimatedTransmitterCoordinate: (row: Int, col: Int)?
    public var safeBlindZoneCoordinate: (row: Int, col: Int)?
    public var maxSignalDbm: Int
    public var minSignalDbm: Int

    public init(rows: Int = 8, cols: Int = 8) {
        self.rows = rows
        self.cols = cols
        self.cells = []
        self.maxSignalDbm = -100
        self.minSignalDbm = -30
        generateInitialGrid()
    }

    private mutating func generateInitialGrid() {
        var generated: [HeatmapGridCell] = []
        for r in 0..<rows {
            for c in 0..<cols {
                // Estado inicial de silencio / calibración
                generated.append(HeatmapGridCell(row: r, col: c, signalIntensity: 0.15, rssiDbm: -85))
            }
        }
        self.cells = generated
    }
}
