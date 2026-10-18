import SwiftUI
import SceneKit

/// Vista Principal de la Pestaña 3: "Visión 3D" (LiDAR Espacial y Reflejos)
public struct Vision3DView: View {
    @StateObject private var viewModel = Vision3DViewModel()
    @State private var showAnomaliesList: Bool = false

    public var body: some View {
        VStack(spacing: 0) {
            // Cabecera Táctica
            TacticalTopBar(
                title: "VISIÓN 3D (LIDAR Y REFLEJOS)",
                statusText: viewModel.isLiDARSupported ? "LIDAR .MESH OK" : "MODO SENSOR",
                statusColor: viewModel.detectedLaserReflections.isEmpty ? TacticalTheme.neonGreen : TacticalTheme.alertRed
            )

            ZStack {
                // Vista de Realidad Aumentada con Malla Matrix
                ARMatrixRepresentable(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)

                // Superposición HUD de Navegación Espacial en Oscuridad
                VStack {
                    // Telemetría Superior
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(viewModel.isMatrixModeActive ? TacticalTheme.neonGreen : TacticalTheme.textMuted)
                                    .frame(width: 8, height: 8)
                                Text("ESTILO MATRIX: \(viewModel.isMatrixModeActive ? "ACTIVO" : "DESACTIVADO")")
                                    .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                                    .foregroundColor(TacticalTheme.neonGreen)
                            }
                            Text("ANCLAJES .MESH: \(viewModel.activeMeshAnchorCount) | POLÍGONOS: \(viewModel.surfacePolygonCount)")
                                .font(TacticalTheme.monoFont(size: 8))
                                .foregroundColor(TacticalTheme.textMuted)
                        }

                        Spacer()

                        // Contador de Anomalías Ópticas Detectadas
                        Button(action: {
                            showAnomaliesList.toggle()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "circle.grid.cross.fill")
                                    .foregroundColor(viewModel.detectedLaserReflections.isEmpty ? TacticalTheme.neonGreen : TacticalTheme.alertRed)
                                Text("ANOMALÍAS: \(viewModel.detectedLaserReflections.count)")
                                    .font(TacticalTheme.monoFont(size: 9, weight: .black))
                                    .foregroundColor(viewModel.detectedLaserReflections.isEmpty ? TacticalTheme.neonGreen : TacticalTheme.alertRed)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(TacticalTheme.cardDarkGray.opacity(0.85))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke((viewModel.detectedLaserReflections.isEmpty ? TacticalTheme.neonGreen : TacticalTheme.alertRed).opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                    .padding(12)

                    Spacer()

                    // Retícula de Escaneo Láser Central
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(TacticalTheme.neonGreen.opacity(0.6), lineWidth: 1)
                                .frame(width: 90, height: 90)

                            Circle()
                                .stroke(TacticalTheme.alertRed.opacity(0.5), lineWidth: 1)
                                .frame(width: 30, height: 30)

                            Path { path in
                                path.move(to: CGPoint(x: 45, y: 0))
                                path.addLine(to: CGPoint(x: 45, y: 90))
                                path.move(to: CGPoint(x: 0, y: 45))
                                path.addLine(to: CGPoint(x: 90, y: 45))
                            }
                            .stroke(TacticalTheme.neonGreen.opacity(0.3), lineWidth: 1)
                            .frame(width: 90, height: 90)
                        }

                        Text("DISTANCIA: \(String(format: "%.2f", viewModel.currentTargetDistance)) M")
                            .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                            .foregroundColor(TacticalTheme.neonGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(TacticalTheme.pureBlack.opacity(0.75))
                            .cornerRadius(3)
                    }

                    Spacer()

                    // Panel de Control Inferior
                    VStack(spacing: 8) {
                        HStack {
                            // Conmutador Modo Matrix Wireframe
                            Button(action: {
                                viewModel.isMatrixModeActive.toggle()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "grid")
                                    Text("MATRIX WIRE")
                                }
                                .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                                .foregroundColor(viewModel.isMatrixModeActive ? TacticalTheme.pureBlack : TacticalTheme.neonGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(viewModel.isMatrixModeActive ? TacticalTheme.neonGreen : TacticalTheme.cardDarkGray)
                                .cornerRadius(4)
                            }

                            Spacer()

                            // Botón de Disparo de Ping Óptico
                            Button(action: {
                                let centerPoint = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
                                viewModel.analyzeLiDAROpticalBounce(at: centerPoint)
                                AudioHapticEngine.shared.triggerRadarPulse()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "scope")
                                    Text("PING LÁSER RETRO-REFLEJO")
                                }
                                .font(TacticalTheme.monoFont(size: 10, weight: .black))
                                .foregroundColor(TacticalTheme.pureBlack)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(TacticalTheme.alertRed)
                                .cornerRadius(4)
                            }

                            // Botón de Test de Nodo 3D
                            Button(action: {
                                let mockPos = SCNVector3(Float.random(in: -0.4...0.4), Float.random(in: -0.2...0.3), -1.2)
                                viewModel.spawnRedAlertBeacon(at: mockPos, reflectance: 0.92, distance: 1.2)
                            }) {
                                Text("SIMULAR")
                                    .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                                    .foregroundColor(TacticalTheme.hudCyan)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(TacticalTheme.cardDarkGray)
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(TacticalTheme.hudCyan.opacity(0.6), lineWidth: 1)
                                    )
                            }
                        }

                        // Slider de Sensibilidad Láser
                        VStack(spacing: 3) {
                            HStack {
                                Text("UMBRAL DE REFLEXIÓN ESPECULAR (LENTE PINHOLE):")
                                    .font(TacticalTheme.monoFont(size: 8))
                                    .foregroundColor(TacticalTheme.textMuted)
                                Spacer()
                                Text("\(Int(viewModel.laserSensitivityThreshold * 100))%")
                                    .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                                    .foregroundColor(TacticalTheme.neonGreen)
                            }

                            Slider(value: $viewModel.laserSensitivityThreshold, in: 0.5...0.98, step: 0.02)
                                .accentColor(TacticalTheme.neonGreen)
                        }
                    }
                    .padding(10)
                    .background(TacticalTheme.cardDarkGray.opacity(0.92))
                    .tacticalCard(borderColor: TacticalTheme.neonGreen.opacity(0.4))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }

                // Modal / Hoja de Anomalías 3D Registradas
                if showAnomaliesList {
                    anomaliesSheetView
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

    // MARK: - Lista de Anomalías Ópticas Registradas

    private var anomaliesSheetView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("REGISTRO DE REFLEJOS LÁSER SOSPECHOSOS")
                    .font(TacticalTheme.monoFont(size: 11, weight: .black))
                    .foregroundColor(TacticalTheme.alertRed)
                Spacer()
                Button(action: { showAnomaliesList = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(TacticalTheme.textMuted)
                }
            }

            if viewModel.detectedLaserReflections.isEmpty {
                Text("NO SE REGISTRAN ANOMALÍAS ESPECULARES EN LA MALLA.")
                    .font(TacticalTheme.monoFont(size: 10))
                    .foregroundColor(TacticalTheme.textMuted)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(viewModel.detectedLaserReflections) { anomaly in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(anomaly.notes)
                                        .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                                        .foregroundColor(TacticalTheme.alertRed)
                                    Spacer()
                                    Text(anomaly.timestamp, style: .time)
                                        .font(TacticalTheme.monoFont(size: 8))
                                        .foregroundColor(TacticalTheme.textMuted)
                                }

                                HStack(spacing: 12) {
                                    Text("COORD 3D: [\(String(format: "%.2f", anomaly.worldPosition.x)), \(String(format: "%.2f", anomaly.worldPosition.y)), \(String(format: "%.2f", anomaly.worldPosition.z))]")
                                        .font(TacticalTheme.monoFont(size: 8))
                                        .foregroundColor(Color.white)
                                    Spacer()
                                    Text("DISTANCIA: \(String(format: "%.2f", anomaly.distanceMeters))m")
                                        .font(TacticalTheme.monoFont(size: 8, weight: .bold))
                                        .foregroundColor(TacticalTheme.neonGreen)
                                }
                            }
                            .padding(8)
                            .tacticalCard(borderColor: TacticalTheme.alertRed.opacity(0.6))
                        }
                    }
                }
            }

            HStack {
                Button(action: {
                    viewModel.resetScan()
                    showAnomaliesList = false
                }) {
                    Text("REINICIAR ESCANEO 3D")
                        .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                        .foregroundColor(TacticalTheme.alertRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(TacticalTheme.cardDarkGray)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(TacticalTheme.alertRed.opacity(0.6), lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(TacticalTheme.pureBlack.opacity(0.95))
        .tacticalCard(borderColor: TacticalTheme.alertRed)
        .padding(24)
        .transition(.scale)
    }
}
