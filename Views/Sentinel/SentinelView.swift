import SwiftUI

/// Vista Principal de la Pestaña 4: "Centinela" (Alarma Volumétrica en Oscuridad)
public struct SentinelView: View {
    @StateObject private var viewModel = SentinelViewModel()
    @State private var selectedSector: String = "PUERTA PRINCIPAL HABITACIÓN"

    let sectorOptions = [
        "PUERTA PRINCIPAL HABITACIÓN",
        "VENTANA CORREDERA / BALCÓN",
        "ACCESO INTERCONECTADO",
        "CAJA DE SEGURIDAD / ARMARIO"
    ]

    public var body: some View {
        ZStack {
            // Fondo estroboscópico en caso de alarma activa
            if viewModel.isAlarmFlashing {
                TacticalTheme.alertRed.edgesIgnoringSafeArea(.all)
            } else {
                TacticalTheme.pureBlack.edgesIgnoringSafeArea(.all)
            }

            VStack(spacing: 0) {
                // Cabecera Táctica
                TacticalTopBar(
                    title: "CENTINELA VOLUMÉTRICO",
                    statusText: viewModel.state.statusDescription.prefix(16).uppercased(),
                    statusColor: statusColorForState
                )

                ScrollView {
                    VStack(spacing: 16) {
                        // Selector de Sector a Monitorear
                        sectorSelectorSection

                        // Núcleo Central de Control (Botón de Armado Táctico)
                        centralArmingSection

                        // Medidor de Variación Volumétrica en Tiempo Real
                        volumetricTelemetrySection

                        // Registro de Incidentes de Intrusión
                        intrusionLogSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var statusColorForState: Color {
        switch viewModel.state {
        case .disarmed: return TacticalTheme.warningAmber
        case .arming: return TacticalTheme.hudCyan
        case .armed: return TacticalTheme.neonGreen
        case .alarmTriggered: return TacticalTheme.alertRed
        }
    }

    // MARK: - Selector de Sector de la Habitación

    private var sectorSelectorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SECTOR BAJO CUSTODIA:")
                .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                .foregroundColor(TacticalTheme.textMuted)

            Menu {
                ForEach(sectorOptions, id: \.self) { sector in
                    Button(action: {
                        selectedSector = sector
                        viewModel.baselineSectorName = sector
                    }) {
                        Text(sector)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(TacticalTheme.neonGreen)
                    Text(selectedSector)
                        .font(TacticalTheme.monoFont(size: 11, weight: .bold))
                        .foregroundColor(Color.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(TacticalTheme.textMuted)
                }
                .padding(10)
                .tacticalCard(backgroundColor: TacticalTheme.cardDarkGray)
            }
            .disabled(viewModel.state != .disarmed)
        }
    }

    // MARK: - Núcleo Central de Armado y Alarma

    private var centralArmingSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Anillos concéntricos HUD
                Circle()
                    .stroke(statusColorForState.opacity(0.2), lineWidth: 2)
                    .frame(width: 220, height: 220)

                Circle()
                    .stroke(statusColorForState.opacity(0.4), lineWidth: 1)
                    .frame(width: 190, height: 190)

                // Botón Circular Central Táctico
                Button(action: {
                    switch viewModel.state {
                    case .disarmed:
                        viewModel.initiateArmingSequence()
                    case .arming:
                        viewModel.disarmSystem()
                    case .armed:
                        viewModel.disarmSystem()
                    case .alarmTriggered:
                        viewModel.disarmSystem()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(TacticalTheme.cardDarkGray)
                            .frame(width: 160, height: 160)
                            .overlay(
                                Circle()
                                    .stroke(statusColorForState, lineWidth: 3)
                                    .shadow(color: statusColorForState.opacity(0.8), radius: 8)
                            )

                        VStack(spacing: 6) {
                            switch viewModel.state {
                            case .disarmed:
                                Image(systemName: "lock.open.shield")
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundColor(TacticalTheme.neonGreen)
                                Text("ARMAR\nSISTEMA")
                                    .font(TacticalTheme.monoFont(size: 13, weight: .black))
                                    .foregroundColor(Color.white)
                                    .multilineTextAlignment(.center)

                            case .arming(let sec):
                                Text("\(sec)")
                                    .font(TacticalTheme.monoFont(size: 50, weight: .black))
                                    .foregroundColor(TacticalTheme.warningAmber)
                                Text("DESPEJE ÁREA")
                                    .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                                    .foregroundColor(TacticalTheme.warningAmber)

                            case .armed:
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundColor(TacticalTheme.neonGreen)
                                Text("CENTINELA\nACTIVO")
                                    .font(TacticalTheme.monoFont(size: 12, weight: .black))
                                    .foregroundColor(TacticalTheme.neonGreen)
                                    .multilineTextAlignment(.center)

                            case .alarmTriggered(let delta, _):
                                Image(systemName: "exclamationmark.octagon.fill")
                                    .font(.system(size: 42, weight: .black))
                                    .foregroundColor(TacticalTheme.alertRed)
                                Text("DESARMAR\n(\(String(format: "%.1f", delta)) CM)")
                                    .font(TacticalTheme.monoFont(size: 11, weight: .black))
                                    .foregroundColor(TacticalTheme.alertRed)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
            }
            .frame(height: 230)

            // Estado y descripción operativa
            Text(viewModel.state.statusDescription)
                .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                .foregroundColor(statusColorForState)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            // Botón de Test de Intrusión (disponible solo cuando el sistema está armado)
            if case .armed = viewModel.state {
                Button(action: {
                    viewModel.simulateIntrusionEvent()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.walk.motion")
                        Text("SIMULAR APERTURA DE PUERTA / INTRUSO (> 5 CM)")
                    }
                    .font(TacticalTheme.monoFont(size: 10, weight: .black))
                    .foregroundColor(TacticalTheme.pureBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(TacticalTheme.alertRed)
                    .cornerRadius(6)
                    .shadow(color: TacticalTheme.alertRed.opacity(0.6), radius: 6)
                }
            }
        }
        .padding(16)
        .tacticalCard(borderColor: statusColorForState.opacity(0.5))
    }

    // MARK: - Telemetría Volumétrica y Umbral 5cm

    private var volumetricTelemetrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DESVIACIÓN DE PROFUNDIDAD:")
                    .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                    .foregroundColor(TacticalTheme.textMuted)

                Spacer()

                Text("UMBRAL CRÍTICO: 5.0 CM")
                    .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                    .foregroundColor(TacticalTheme.alertRed)
            }

            // Barra de Desviación
            TacticalGaugeBar(
                value: min(1.0, viewModel.currentDisplacementCm / 10.0),
                label: "DELTA GEOMÉTRICO DETECTADO",
                detailText: "\(String(format: "%.2f", viewModel.currentDisplacementCm)) cm",
                alertThreshold: 0.5 // 5cm / 10cm = 0.5
            )

            HStack {
                Text("DISTANCIA MEDIA AL BLANCO:")
                    .font(TacticalTheme.monoFont(size: 9))
                    .foregroundColor(TacticalTheme.textMuted)
                Spacer()
                Text("\(String(format: "%.2f", viewModel.averageDepthMeters)) METROS")
                    .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                    .foregroundColor(TacticalTheme.neonGreen)
            }
        }
        .padding(12)
        .tacticalCard()
    }

    // MARK: - Registro de Incidentes de Intrusión

    private var intrusionLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("HISTORIAL DE ALERTAS CENTINELA")
                    .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                    .foregroundColor(TacticalTheme.neonGreen)

                Spacer()

                Text("\(viewModel.intrusionLogs.count) INCIDENTES")
                    .font(TacticalTheme.monoFont(size: 9))
                    .foregroundColor(TacticalTheme.textMuted)
            }

            if viewModel.intrusionLogs.isEmpty {
                Text("NO SE REGISTRAN VIOLACIONES DE PERÍMETRO.")
                    .font(TacticalTheme.monoFont(size: 9))
                    .foregroundColor(TacticalTheme.textMuted)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.intrusionLogs) { log in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.sector.uppercased())
                                .font(TacticalTheme.monoFont(size: 10, weight: .black))
                                .foregroundColor(TacticalTheme.alertRed)
                            Text(log.timestamp, style: .time)
                                .font(TacticalTheme.monoFont(size: 8))
                                .foregroundColor(TacticalTheme.textMuted)
                        }

                        Spacer()

                        Text("+\(String(format: "%.1f", log.deltaDisplacementCm)) CM")
                            .font(TacticalTheme.monoFont(size: 12, weight: .black))
                            .foregroundColor(TacticalTheme.alertRed)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(TacticalTheme.alertRed.opacity(0.15))
                            .cornerRadius(4)
                    }
                    .padding(8)
                    .background(TacticalTheme.cardDarkGray)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(TacticalTheme.alertRed.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding(12)
        .tacticalCard()
    }
}
