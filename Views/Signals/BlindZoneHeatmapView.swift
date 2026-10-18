import SwiftUI

/// Vista del Submódulo: Mapeo de Zonas Ciegas (Fusión de Intensidad RF con Posición Local)
public struct BlindZoneHeatmapView: View {
    @ObservedObject var viewModel: SignalsViewModel
    @State private var is3DPerspective: Bool = false

    public var body: some View {
        VStack(spacing: 12) {
            // Cabecera con telemetría de radiofrecuencia
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MAPEO ESPACIAL DE ZONAS CIEGAS")
                        .font(TacticalTheme.monoFont(size: 13, weight: .bold))
                        .foregroundColor(TacticalTheme.neonGreen)

                    Text("FUSIÓN ELECTROMAGNÉTICA BLE/WI-FI // CUADRÍCULA 8x8")
                        .font(TacticalTheme.monoFont(size: 9))
                        .foregroundColor(TacticalTheme.textMuted)
                }

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        is3DPerspective.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: is3DPerspective ? "cube.transparent" : "square.grid.2x2")
                        Text(is3DPerspective ? "MODO 3D" : "MODO 2D")
                    }
                    .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                    .foregroundColor(TacticalTheme.pureBlack)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(TacticalTheme.neonGreen)
                    .cornerRadius(4)
                }
            }
            .padding(.horizontal, 4)

            // Resumen de Vectores Tácticos (Pico Sospechoso vs Punto Ciego Seguro)
            VStack(spacing: 6) {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(TacticalTheme.alertRed)
                            .frame(width: 8, height: 8)
                        Text("ORIGEN SOSPECHOSO (TRANSMISOR):")
                            .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                            .foregroundColor(TacticalTheme.alertRed)
                    }
                    Spacer()
                    Text(viewModel.detectedTransmitterLocation)
                        .font(TacticalTheme.monoFont(size: 9))
                        .foregroundColor(Color.white)
                }

                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(TacticalTheme.neonGreen)
                            .frame(width: 8, height: 8)
                        Text("PUNTO CIEGO SEGURO:")
                            .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                            .foregroundColor(TacticalTheme.neonGreen)
                    }
                    Spacer()
                    Text(viewModel.safeBlindZoneLocation)
                        .font(TacticalTheme.monoFont(size: 9))
                        .foregroundColor(Color.white)
                }
            }
            .padding(10)
            .tacticalCard(borderColor: TacticalTheme.neonGreen.opacity(0.4), backgroundColor: TacticalTheme.cardDarkGray)

            // Representación Gráfica del Mapa Térmico
            ZStack {
                // Fondo táctico
                Rectangle()
                    .fill(TacticalTheme.pureBlack)
                    .overlay(
                        // Cuadrícula táctica milimétrica
                        GridPatternShape(spacing: 20)
                            .stroke(TacticalTheme.neonGreen.opacity(0.08), lineWidth: 1)
                    )

                // Renderizado de las Celdas del Retículo Térmico
                VStack(spacing: 3) {
                    ForEach(0..<viewModel.heatmapGrid.rows, id: \.self) { row in
                        HStack(spacing: 3) {
                            ForEach(0..<viewModel.heatmapGrid.cols, id: \.self) { col in
                                if let cell = viewModel.heatmapGrid.cells.first(where: { $0.row == row && $0.col == col }) {
                                    HeatmapCellView(
                                        cell: cell,
                                        isUserHere: (viewModel.currentPosition.row == row && viewModel.currentPosition.col == col)
                                    )
                                    .onTapGesture {
                                        viewModel.moveUserPosition(row: row, col: col)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(10)
                .rotation3DEffect(
                    .degrees(is3DPerspective ? 32 : 0),
                    axis: (x: 1.0, y: 0.0, z: 0.0),
                    perspective: 0.5
                )
                .scaleEffect(is3DPerspective ? 0.9 : 1.0)
            }
            .frame(height: 280)
            .tacticalHUDFrame(color: TacticalTheme.neonGreen)
            .tacticalCard(borderColor: TacticalTheme.neonGreen.opacity(0.5))

            // Controles de Simulación y Calibración
            HStack(spacing: 8) {
                Button(action: {
                    // Reubica aleatoriamente el origen del transmisor para simular otra habitación
                    let randR = Int.random(in: 1...6)
                    let randC = Int.random(in: 1...6)
                    viewModel.simulateRFEnvironment(transmitterRow: randR, transmitterCol: randC)
                    AudioHapticEngine.shared.triggerRadarPulse()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("RECALIBRAR ENTORNO")
                    }
                    .font(TacticalTheme.monoFont(size: 11, weight: .bold))
                    .foregroundColor(TacticalTheme.neonGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(TacticalTheme.cardDarkGray)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(TacticalTheme.neonGreen.opacity(0.6), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 12)
    }
}

/// Celda individual del mapa térmico RF
struct HeatmapCellView: View {
    let cell: HeatmapGridCell
    let isUserHere: Bool

    var cellColor: Color {
        if cell.isTransmitterPeak {
            return TacticalTheme.alertRed
        } else if cell.isSafeZone {
            return TacticalTheme.neonGreen.opacity(0.85)
        } else {
            // Gradiente térmico según intensidad de la señal
            let intensity = cell.signalIntensity
            if intensity > 0.7 {
                return TacticalTheme.alertRed.opacity(intensity)
            } else if intensity > 0.45 {
                return TacticalTheme.warningAmber.opacity(intensity)
            } else if intensity > 0.25 {
                return TacticalTheme.hudCyan.opacity(intensity * 0.7)
            } else {
                return TacticalTheme.neonGreen.opacity(0.15)
            }
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(cellColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(cell.isTransmitterPeak ? Color.white : TacticalTheme.neonGreen.opacity(0.2), lineWidth: 1)
                )

            if cell.isTransmitterPeak {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            } else if cell.isSafeZone {
                Image(systemName: "shield.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
            }

            if isUserHere {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle().fill(TacticalTheme.neonGreen).frame(width: 6, height: 6)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1.0, contentMode: .fit)
    }
}

/// Forma auxiliar de cuadrícula milimétrica táctica
struct GridPatternShape: Shape {
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for x in stride(from: 0, to: rect.width, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        for y in stride(from: 0, to: rect.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return path
    }
}
