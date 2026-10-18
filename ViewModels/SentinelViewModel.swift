import Foundation
import ARKit
import Combine
import SwiftUI

/// ViewModel para el Sistema Centinela de Alarma Volumétrica en Oscuridad Absoluta
public final class SentinelViewModel: NSObject, ObservableObject {
    // MARK: - Estado Publicado
    @Published public var state: SentinelState = .disarmed
    @Published public var currentDisplacementCm: Double = 0.0
    @Published public var baselineSectorName: String = "ACCESO_HOTEL_SECTOR_ALFA"
    @Published public var baselineCaptured: Bool = false
    @Published public var intrusionLogs: [SentinelIntrusionLog] = []
    @Published public var isAlarmFlashing: Bool = false
    @Published public var sensitivityThresholdCm: Double = 5.0 // Umbral estricto de 5 centímetros
    @Published public var averageDepthMeters: Float = 2.15

    // MARK: - Propiedades de Detección ARKit
    public let arSession = ARSession()
    private var baselineSnapshot: SentinelDepthSnapshot?
    private var armingTimer: AnyCancellable?
    private var monitoringTimer: AnyCancellable?
    private var alarmPulseTimer: AnyCancellable?

    public override init() {
        super.init()
    }

    // MARK: - Proceso de Armado del Centinela

    /// Inicia la secuencia de armado táctico con cuenta regresiva para posicionar el dispositivo
    public func initiateArmingSequence() {
        guard state == .disarmed else { return }

        var countdown = 5
        state = .arming(secondsRemaining: countdown)
        AudioHapticEngine.shared.triggerWarningHaptic()
        AudioHapticEngine.shared.playTone(frequency: 1000, duration: 0.1)

        armingTimer?.cancel()
        armingTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                countdown -= 1

                if countdown > 0 {
                    self.state = .arming(secondsRemaining: countdown)
                    AudioHapticEngine.shared.playTone(frequency: 800 + Double((5 - countdown) * 150), duration: 0.08)
                    AudioHapticEngine.shared.triggerRadarPulse()
                } else {
                    self.armingTimer?.cancel()
                    self.captureBaselineAndArm()
                }
            }
    }

    /// Captura el snapshot tridimensional de referencia geométrica del LiDAR y activa el centinela
    private func captureBaselineAndArm() {
        // En un dispositivo físico con LiDAR, extraemos los datos de sceneDepth
        // Generamos una matriz de muestreo 16x16 de distancias focales
        var simulatedMatrix: [[Float]] = []
        let nominalDistance: Float = 2.40 // 2.4 metros hasta la puerta del cuarto

        for _ in 0..<16 {
            var row: [Float] = []
            for _ in 0..<16 {
                let jitter = Float.random(in: -0.015...0.015)
                row.append(nominalDistance + jitter)
            }
            simulatedMatrix.append(row)
        }

        self.baselineSnapshot = SentinelDepthSnapshot(
            sectorName: self.baselineSectorName,
            depthMatrix: simulatedMatrix,
            gridResolution: 16
        )
        self.baselineCaptured = true
        self.state = .armed

        AudioHapticEngine.shared.triggerSuccessHaptic()
        AudioHapticEngine.shared.playTone(frequency: 1600, duration: 0.25)

        startContinuousMonitoring()
    }

    // MARK: - Ciclo de Monitoreo Continuo de Profundidad

    private func startContinuousMonitoring() {
        monitoringTimer?.cancel()
        monitoringTimer = Timer.publish(every: 0.1, on: .main, in: .common) // Muestreo a 10 Hz
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, case .armed = self.state else { return }
                self.evaluateVolumetricDisplacement()
            }
    }

    /// Compara las distancias actuales del LiDAR contra el snapshot de referencia
    /// Si detecta una variación > 5.0 cm en cualquier celda de la matriz, activa el estado de intrusión
    private func evaluateVolumetricDisplacement() {
        guard let baseline = baselineSnapshot else { return }

        // Muestreo de profundidad actual (en dispositivo real se lee de arSession.currentFrame?.sceneDepth)
        var maxDeltaFoundMeters: Float = 0.0

        for r in 0..<baseline.gridResolution {
            for c in 0..<baseline.gridResolution {
                let baseVal = baseline.depthMatrix[r][c]
                // Supongamos fluctuación normal de sensor (+/- 8 mm en reposo)
                var currentVal = baseVal + Float.random(in: -0.008...0.008)

                // Si se activa una simulación manual o se cruza un objeto:
                if self.isSimulatedIntrusionPending {
                    // Intrusión de prueba: puerta abriéndose o persona interponiéndose (delta de 18 cm)
                    currentVal = baseVal - 0.18
                }

                let delta = abs(currentVal - baseVal)
                if delta > maxDeltaFoundMeters {
                    maxDeltaFoundMeters = delta
                }
            }
        }

        let deltaCm = Double(maxDeltaFoundMeters * 100.0)
        self.currentDisplacementCm = deltaCm

        // Verificación de umbral de 5 centímetros
        if deltaCm >= self.sensitivityThresholdCm {
            triggerIntrusionAlarm(deltaCm: deltaCm)
        }
    }

    // Bandera para pruebas interactivas en UI / Simulador
    public var isSimulatedIntrusionPending: Bool = false

    /// Simula la apertura de la puerta o cruce de un intruso para pruebas tácticas
    public func simulateIntrusionEvent() {
        isSimulatedIntrusionPending = true
    }

    // MARK: - Alerta de Intrusión

    private func triggerIntrusionAlarm(deltaCm: Double) {
        self.isSimulatedIntrusionPending = false
        self.state = .alarmTriggered(maxDeltaCm: deltaCm, triggerTime: Date())

        let log = SentinelIntrusionLog(
            sector: baselineSectorName,
            deltaDisplacementCm: deltaCm,
            durationSeconds: 1.0
        )
        self.intrusionLogs.insert(log, at: 0)

        // Activación de sirena militar y hápticos intensos
        AudioHapticEngine.shared.playTacticalSiren(cycles: 6)

        // Estroboscopio visual en pantalla
        alarmPulseTimer?.cancel()
        alarmPulseTimer = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case .alarmTriggered = self.state {
                    self.isAlarmFlashing.toggle()
                    AudioHapticEngine.shared.triggerIntrusionAlertHaptics()
                } else {
                    self.alarmPulseTimer?.cancel()
                    self.isAlarmFlashing = false
                }
            }
    }

    // MARK: - Desarmado de Emergencia

    public func disarmSystem() {
        monitoringTimer?.cancel()
        armingTimer?.cancel()
        alarmPulseTimer?.cancel()
        state = .disarmed
        isAlarmFlashing = false
        currentDisplacementCm = 0.0
        AudioHapticEngine.shared.triggerSuccessHaptic()
    }
}
