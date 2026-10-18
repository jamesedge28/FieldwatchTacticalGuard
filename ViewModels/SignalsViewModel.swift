import Foundation
import CoreBluetooth
import Combine
import SwiftUI

/// ViewModel para la gestión del escáner pasivo CoreBluetooth y el mapeo de zonas ciegas RF
public final class SignalsViewModel: NSObject, ObservableObject {
    // MARK: - Estado Publicado
    @Published public var discoveredDevices: [BLEDeviceModel] = []
    @Published public var isScanning: Bool = false
    @Published public var bluetoothState: CBManagerState = .unknown
    @Published public var selectedDevice: BLEDeviceModel? = nil
    
    // Submódulo Mapeo de Zonas Ciegas
    @Published public var heatmapGrid: HeatmapGridData = HeatmapGridData(rows: 8, cols: 8)
    @Published public var currentPosition: (row: Int, col: Int) = (4, 4)
    @Published public var isGeneratingHeatmap: Bool = false
    @Published public var detectedTransmitterLocation: String = "PENDIENTE DE TRIANGULACIÓN"
    @Published public var safeBlindZoneLocation: String = "LOCALIZANDO SECTOR APANTALLADO"
    @Published public var maxObservedPowerDbm: Int = -100

    // MARK: - Propiedades Privadas
    private var centralManager: CBCentralManager!
    private var deviceMap: [UUID: BLEDeviceModel] = [:]
    private var simulationTimer: AnyCancellable?
    private var radarAudioDebounce: Date = Date()

    public override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .userInitiated), options: [CBCentralManagerOptionShowPowerAlertKey: true])
        setupInitialHeatmap()
    }

    // MARK: - Control de Escaneo Pasivo

    public func startPassiveScan() {
        guard bluetoothState == .poweredOn else {
            print("[BLE] Bluetooth no disponible, activando modo simulación táctica...")
            startTacticalSimulation()
            isScanning = true
            return
        }

        isScanning = true
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
    }

    public func stopPassiveScan() {
        isScanning = false
        centralManager.stopScan()
        simulationTimer?.cancel()
    }

    public func clearDevices() {
        deviceMap.removeAll()
        discoveredDevices.removeAll()
    }

    // MARK: - Mapeo de Zonas Ciegas (Fusión de Intensidad y Coordenadas Locales)

    private func setupInitialHeatmap() {
        heatmapGrid = HeatmapGridData(rows: 8, cols: 8)
        simulateRFEnvironment(transmitterRow: 2, transmitterCol: 6)
    }

    /// Simula y proyecta el gradiente electromagnético en la sala para ubicar el transmisor y el punto ciego seguro
    public func simulateRFEnvironment(transmitterRow: Int, transmitterCol: Int) {
        var updatedCells: [HeatmapGridCell] = []
        var maxIntensity: Double = 0.0
        var minIntensity: Double = 1.0
        var bestBlindSpot = (row: 0, col: 0)

        for r in 0..<heatmapGrid.rows {
            for c in 0..<heatmapGrid.cols {
                // Cálculo de distancia euclidiana al punto emisor
                let distance = sqrt(pow(Double(r - transmitterRow), 2) + pow(Double(c - transmitterCol), 2))
                // Modelo de atenuación de espacio libre inverso al cuadrado
                let rawAttenuation = 1.0 / max(1.0, distance * 0.9)
                let noise = Double.random(in: -0.04...0.04)
                let intensity = max(0.05, min(1.0, rawAttenuation + noise))
                let rssi = Int(-30 - ((1.0 - intensity) * 65.0))

                let isPeak = (r == transmitterRow && c == transmitterCol)
                if intensity > maxIntensity {
                    maxIntensity = intensity
                }
                if intensity < minIntensity {
                    minIntensity = intensity
                    bestBlindSpot = (r, c)
                }

                updatedCells.append(HeatmapGridCell(
                    row: r,
                    col: c,
                    signalIntensity: intensity,
                    rssiDbm: rssi,
                    isTransmitterPeak: isPeak,
                    isSafeZone: false
                ))
            }
        }

        // Marcar la zona ciega óptima
        for i in 0..<updatedCells.count {
            if updatedCells[i].row == bestBlindSpot.row && updatedCells[i].col == bestBlindSpot.col {
                updatedCells[i].isSafeZone = true
            }
        }

        self.heatmapGrid.cells = updatedCells
        self.heatmapGrid.estimatedTransmitterCoordinate = (transmitterRow, transmitterCol)
        self.heatmapGrid.safeBlindZoneCoordinate = bestBlindSpot
        self.detectedTransmitterLocation = "SECTOR CUADRÍCULA [\(transmitterRow), \(transmitterCol)] // VECTOR N-E"
        self.safeBlindZoneLocation = "SECTOR CUADRÍCULA [\(bestBlindSpot.row), \(bestBlindSpot.col)] // APANTALLAMIENTO ÓPTIMO"
    }

    /// Desplaza la posición del usuario en el mapa y reajusta la triangulación
    public func moveUserPosition(row: Int, col: Int) {
        guard row >= 0 && row < heatmapGrid.rows && col >= 0 && col < heatmapGrid.cols else { return }
        self.currentPosition = (row, col)

        if let cell = heatmapGrid.cells.first(where: { $0.row == row && $0.col == col }) {
            // Reproducir click geiger acústico según la proximidad del usuario al pico
            if Date().timeIntervalSince(radarAudioDebounce) > 0.25 {
                AudioHapticEngine.shared.playRFGeigerClick(rssiIntensity: cell.signalIntensity)
                radarAudioDebounce = Date()
            }
        }
    }

    // MARK: - Modo Simulación Táctica (Para pruebas en simulador o sin hardware BLE cercano)

    private func startTacticalSimulation() {
        simulationTimer?.cancel()
        
        // Dispositivos simulados de contrainteligencia
        let mockTargets = [
            ("LENS_STREAM_08B", -42, BLEDeviceCategory.suspiciousTransmitter, ["FFE0", "180A"]),
            ("AIR_TAG_BEACON_9", -58, BLEDeviceCategory.surveillanceBeacon, ["FD6F"]),
            ("SONY_AUDIO_TX", -74, BLEDeviceCategory.audioVideoLink, ["1800", "1801"]),
            ("APPLE_WATCH_7A2", -65, BLEDeviceCategory.genericPeripheral, ["180D"]),
            ("PICO_REC_BUG_X", -38, BLEDeviceCategory.suspiciousTransmitter, ["FFF1"])
        ]

        var counter = 0
        simulationTimer = Timer.publish(every: 1.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isScanning else { return }
                let target = mockTargets[counter % mockTargets.count]
                let jitterRssi = target.1 + Int.random(in: -4...4)
                
                let simulatedDevice = BLEDeviceModel(
                    id: UUID(uuidString: "00000000-0000-0000-0000-00000000000\(counter % 5)") ?? UUID(),
                    name: target.0,
                    rssi: jitterRssi,
                    txPower: -59,
                    serviceUUIDs: target.3,
                    isConnectable: true,
                    lastSeen: Date(),
                    category: target.2
                )

                self.deviceMap[simulatedDevice.id] = simulatedDevice
                self.discoveredDevices = Array(self.deviceMap.values).sorted(by: { $0.rssi > $1.rssi })
                counter += 1
            }
    }
}

// MARK: - CBCentralManagerDelegate

extension SignalsViewModel: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.bluetoothState = central.state
            if central.state == .poweredOn {
                if self.isScanning {
                    self.startPassiveScan()
                }
            } else {
                print("[BLE] Estado de Bluetooth alterado: \(central.state.rawValue)")
            }
        }
    }

    public func centralManager(_ central: CBCentralManager,
                               didDiscover peripheral: CBPeripheral,
                               advertisementData: [String : Any],
                               rssi RSSI: NSNumber) {
        let rssiInt = RSSI.intValue
        // Descartar lecturas inválidas
        guard rssiInt < 0 && rssiInt > -110 else { return }

        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
        let txPower = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int
        var serviceStrings: [String] = []

        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            serviceStrings = serviceUUIDs.map { $0.uuidString }
        }

        let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? true

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            var device = self.deviceMap[peripheral.identifier] ?? BLEDeviceModel(
                id: peripheral.identifier,
                name: name,
                rssi: rssiInt,
                txPower: txPower,
                serviceUUIDs: serviceStrings,
                isConnectable: isConnectable
            )

            device.previousRssi = device.rssi
            device.rssi = rssiInt
            device.lastSeen = Date()
            
            // Actualizar mapa
            self.deviceMap[peripheral.identifier] = device
            self.discoveredDevices = Array(self.deviceMap.values).sorted(by: { $0.rssi > $1.rssi })

            // Alerta acústica si detecta un transmisor sospechoso con señal intensa (> -45 dBm)
            if device.category == .suspiciousTransmitter && device.rssi > -45 {
                AudioHapticEngine.shared.triggerWarningHaptic()
            }
        }
    }
}
