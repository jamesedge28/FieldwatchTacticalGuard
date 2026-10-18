import SwiftUI

/// Vista Principal de la Pestaña 2: "Escáner Visual" (Detección Óptica e Infrarroja)
public struct VisualScannerView: View {
    @StateObject private var viewModel = VisualScannerViewModel()
    @State private var showControlsOverlay: Bool = true

    public var body: some View {
        VStack(spacing: 0) {
            // Cabecera Táctica
            TacticalTopBar(
                title: "ESCÁNER ÓPTICO E INFRARROJO",
                statusText: viewModel.isRunning ? "ÓPTICA ACTIVA" : "OFFLINE",
                statusColor: viewModel.opticalAnomalyDetected ? TacticalTheme.alertRed : TacticalTheme.neonGreen
            )

            // Contenedor de Visor Óptico
            ZStack {
                // Flujo de Cámara Filtrado con CIFilter
                FilteredCameraStreamView(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)

                // Retícula Táctica de Contrainteligencia HUD
                TacticalOpticalHUDOverlay(viewModel: viewModel)

                // Banner de Alerta de Anomalía Óptica (Destello IR de Cámara Oculta)
                if viewModel.opticalAnomalyDetected {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(TacticalTheme.pureBlack)

                            VStack(alignment: .leading, spacing: 1) {
                                Text("¡DESTELLO INFRARROJO DETECTADO!")
                                    .font(TacticalTheme.monoFont(size: 11, weight: .black))
                                    .foregroundColor(TacticalTheme.pureBlack)
                                Text("Posible iluminador LED 850/940nm de visión nocturna de cámara oculta.")
                                    .font(TacticalTheme.monoFont(size: 8, weight: .semibold))
                                    .foregroundColor(TacticalTheme.pureBlack)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(TacticalTheme.alertRed)
                        .cornerRadius(6)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Panel Inferior de Calibración Óptica Desplegable
                VStack {
                    Spacer()

                    VStack(spacing: 10) {
                        // Selector de Filtro Óptico
                        Picker("Filtro", selection: $viewModel.filterMode) {
                            ForEach(VisualScannerViewModel.OpticalFilterMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        // Control Deslizante de Umbral de Aislamiento IR
                        VStack(spacing: 4) {
                            HStack {
                                Text("CORTE DE LUMINANCIA IR:")
                                    .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                                    .foregroundColor(TacticalTheme.textMuted)
                                Spacer()
                                Text("\(Int(viewModel.irThreshold * 100))%")
                                    .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                                    .foregroundColor(TacticalTheme.neonGreen)
                            }

                            Slider(value: $viewModel.irThreshold, in: 0.5...0.98, step: 0.02)
                                .accentColor(TacticalTheme.neonGreen)
                        }

                        // Ganancia de Exposición
                        HStack(spacing: 8) {
                            Text("GANANCIA EV:")
                                .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                                .foregroundColor(TacticalTheme.textMuted)

                            Slider(value: $viewModel.exposureBoost, in: 0.5...4.0, step: 0.25)
                                .accentColor(TacticalTheme.neonGreen)

                            // Botón de Test de Destello Infrarrojo
                            Button(action: {
                                // Simula la aparición de un LED IR en el centro para pruebas
                                if viewModel.detectedInfraredHotspots.isEmpty {
                                    viewModel.detectedInfraredHotspots = [CGPoint(x: 0.5, y: 0.45)]
                                    viewModel.opticalAnomalyDetected = true
                                    AudioHapticEngine.shared.triggerIntrusionAlertHaptics()
                                } else {
                                    viewModel.detectedInfraredHotspots.removeAll()
                                    viewModel.opticalAnomalyDetected = false
                                }
                            }) {
                                Text(viewModel.opticalAnomalyDetected ? "LIMPIAR" : "TEST IR")
                                    .font(TacticalTheme.monoFont(size: 9, weight: .black))
                                    .foregroundColor(TacticalTheme.pureBlack)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(TacticalTheme.hudCyan)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding(12)
                    .background(TacticalTheme.cardDarkGray.opacity(0.92))
                    .tacticalCard(borderColor: TacticalTheme.neonGreen.opacity(0.4))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
        }
        .background(TacticalTheme.pureBlack)
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }
}

/// Retícula y elementos HUD tácticos sobre la cámara
struct TacticalOpticalHUDOverlay: View {
    @ObservedObject var viewModel: VisualScannerViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Marco HUD
                Rectangle()
                    .stroke(TacticalTheme.neonGreen.opacity(0.2), lineWidth: 1)
                    .padding(8)

                // Retícula Central de Tiro
                CrosshairShape()
                    .stroke(TacticalTheme.neonGreen.opacity(0.4), lineWidth: 1)
                    .frame(width: 80, height: 80)

                Circle()
                    .stroke(TacticalTheme.neonGreen.opacity(0.3), lineWidth: 1)
                    .frame(width: 140, height: 140)

                // Telemetría Superior en Esquinas
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ISO: AUTO-BOOST")
                                .font(TacticalTheme.monoFont(size: 8, weight: .bold))
                                .foregroundColor(TacticalTheme.neonGreen)
                            Text("FPS: 30.0 FIX")
                                .font(TacticalTheme.monoFont(size: 8))
                                .foregroundColor(TacticalTheme.textMuted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("FILTRO: \(viewModel.filterMode.rawValue.prefix(12))")
                                .font(TacticalTheme.monoFont(size: 8, weight: .bold))
                                .foregroundColor(TacticalTheme.hudCyan)
                            Text("ESPECTRO: 850-940nm")
                                .font(TacticalTheme.monoFont(size: 8))
                                .foregroundColor(TacticalTheme.textMuted)
                        }
                    }
                    .padding(16)

                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }
}

/// Cruz central del visor
struct CrosshairShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let midY = rect.midY
        let length: CGFloat = 16

        // Línea vertical superior e inferior
        path.move(to: CGPoint(x: midX, y: rect.minY))
        path.addLine(to: CGPoint(x: midX, y: rect.minY + length))
        path.move(to: CGPoint(x: midX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: midX, y: rect.maxY))

        // Línea horizontal izquierda y derecha
        path.move(to: CGPoint(x: rect.minX, y: midY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: midY))
        path.move(to: CGPoint(x: rect.maxX - length, y: midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: midY))

        return path
    }
}
