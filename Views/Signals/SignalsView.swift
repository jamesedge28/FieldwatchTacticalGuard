import SwiftUI

/// Vista Principal de la Pestaña 1: "Señales" (Ecosistema Radiofrecuencia)
public struct SignalsView: View {
    @StateObject private var viewModel = SignalsViewModel()
    @State private var selectedSubtab: SignalsSubTab = .scanner

    public enum SignalsSubTab: String, CaseIterable {
        case scanner = "ESCÁNER BLE PASIVO"
        case blindZoneMapping = "MAPEO DE ZONAS CIEGAS"
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Barra de Estado Táctica
            TacticalTopBar(
                title: "ECOSISTEMA RADIOFRECUENCIA",
                statusText: viewModel.isScanning ? "ESCÁNER ACTIVO" : "STANDBY",
                statusColor: viewModel.isScanning ? TacticalTheme.neonGreen : TacticalTheme.warningAmber
            )

            // Selector Táctico de Submódulo
            Picker("Modo Señales", selection: $selectedSubtab) {
                ForEach(SignalsSubTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(TacticalTheme.pureBlack)

            // Contenido Dinámico según Subpestaña
            ScrollView {
                VStack(spacing: 16) {
                    if selectedSubtab == .scanner {
                        bleScannerContentView
                    } else {
                        BlindZoneHeatmapView(viewModel: viewModel)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(TacticalTheme.pureBlack)
        }
        .background(TacticalTheme.pureBlack)
        .onAppear {
            viewModel.startPassiveScan()
        }
        .onDisappear {
            viewModel.stopPassiveScan()
        }
    }

    // MARK: - Submódulo: Lista de Dispositivos BLE Pasivo

    private var bleScannerContentView: some View {
        VStack(spacing: 12) {
            // Panel de Control del Escáner
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MONITOR PASIVO CBCENTRAL")
                        .font(TacticalTheme.monoFont(size: 11, weight: .bold))
                        .foregroundColor(TacticalTheme.neonGreen)
                    Text("DISPOSITIVOS DETECTADOS: \(viewModel.discoveredDevices.count)")
                        .font(TacticalTheme.monoFont(size: 9))
                        .foregroundColor(TacticalTheme.textMuted)
                }

                Spacer()

                Button(action: {
                    if viewModel.isScanning {
                        viewModel.stopPassiveScan()
                    } else {
                        viewModel.startPassiveScan()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isScanning ? "stop.fill" : "play.fill")
                        Text(viewModel.isScanning ? "DETENER" : "ESCANEAR")
                    }
                    .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                    .foregroundColor(TacticalTheme.pureBlack)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(viewModel.isScanning ? TacticalTheme.alertRed : TacticalTheme.neonGreen)
                    .cornerRadius(4)
                }

                Button(action: {
                    viewModel.clearDevices()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(TacticalTheme.textMuted)
                        .padding(6)
                        .background(TacticalTheme.cardDarkGray)
                        .cornerRadius(4)
                }
            }
            .padding(12)
            .tacticalCard()
            .padding(.horizontal, 16)

            // Lista de Dispositivos BLE
            if viewModel.discoveredDevices.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: TacticalTheme.neonGreen))
                        .scaleEffect(1.2)
                    
                    Text("BARRIDO ESPECTRAL EN CURSO...")
                        .font(TacticalTheme.monoFont(size: 11, weight: .semibold))
                        .foregroundColor(TacticalTheme.neonGreenDimmed)

                    Text("Detectando paquetes de anuncio BLE y balizas no autorizadas en proximidad inmediata.")
                        .font(TacticalTheme.monoFont(size: 9))
                        .foregroundColor(TacticalTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.discoveredDevices) { device in
                        BLEDeviceCardView(device: device)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

/// Tarjeta de visualización táctica individual de un dispositivo BLE
struct BLEDeviceCardView: View {
    let device: BLEDeviceModel

    var categoryColor: Color {
        switch device.category {
        case .suspiciousTransmitter: return TacticalTheme.alertRed
        case .surveillanceBeacon: return TacticalTheme.warningAmber
        case .audioVideoLink: return TacticalTheme.hudCyan
        case .genericPeripheral: return TacticalTheme.neonGreen
        case .unknown: return TacticalTheme.textMuted
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Nombre y Categoría
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name.uppercased())
                        .font(TacticalTheme.monoFont(size: 13, weight: .black))
                        .foregroundColor(device.category == .suspiciousTransmitter ? TacticalTheme.alertRed : Color.white)

                    Text(device.id.uuidString)
                        .font(TacticalTheme.monoFont(size: 8))
                        .foregroundColor(TacticalTheme.textMuted)
                        .lineLimit(1)
                }

                Spacer()

                // Insignia de Clasificación
                Text(device.category.rawValue)
                    .font(TacticalTheme.monoFont(size: 8, weight: .bold))
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(categoryColor.opacity(0.15))
                    .cornerRadius(3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(categoryColor.opacity(0.5), lineWidth: 1)
                    )
            }

            // Barra Medidora de Señal RSSI
            TacticalGaugeBar(
                value: device.normalizedSignal,
                label: "FUERZA SEÑAL (RSSI)",
                detailText: "\(device.rssi) dBm (~\(String(format: "%.1f", device.estimatedDistanceMeters))m)"
            )

            // Detalles Adicionales Tácticos
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("TX:")
                        .font(TacticalTheme.monoFont(size: 9))
                        .foregroundColor(TacticalTheme.textMuted)
                    Text(device.txPower != nil ? "\(device.txPower!) dBm" : "N/D")
                        .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                        .foregroundColor(TacticalTheme.neonGreen)
                }

                HStack(spacing: 4) {
                    Text("CONECTABLE:")
                        .font(TacticalTheme.monoFont(size: 9))
                        .foregroundColor(TacticalTheme.textMuted)
                    Text(device.isConnectable ? "SÍ" : "NO (MODO BALIZA)")
                        .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                        .foregroundColor(device.isConnectable ? TacticalTheme.neonGreen : TacticalTheme.warningAmber)
                }

                Spacer()

                Text("HACE \(Int(Date().timeIntervalSince(device.lastSeen)))s")
                    .font(TacticalTheme.monoFont(size: 8))
                    .foregroundColor(TacticalTheme.textMuted)
            }
        }
        .padding(12)
        .tacticalCard(
            borderColor: device.category == .suspiciousTransmitter ? TacticalTheme.alertRed.opacity(0.7) : TacticalTheme.neonGreen.opacity(0.25),
            backgroundColor: TacticalTheme.cardDarkGray
        )
    }
}
