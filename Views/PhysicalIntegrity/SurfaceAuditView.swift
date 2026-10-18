import SwiftUI

/// Submódulo: Auditoría de Microrrelieves en Paredes y Cerraduras (< 1.0 mm)
public struct SurfaceAuditView: View {
    @ObservedObject var viewModel: PhysicalIntegrityViewModel

    public var body: some View {
        VStack(spacing: 14) {
            // Cabecera del Submódulo
            VStack(alignment: .leading, spacing: 3) {
                Text("INSPECCIÓN SUB-MILIMÉTRICA DE SUPERFICIES")
                    .font(TacticalTheme.monoFont(size: 11, weight: .bold))
                    .foregroundColor(TacticalTheme.neonGreen)

                Text("DETECCIÓN DE MICRÓFONOS DE CONTACTO Y FORZADO (< 1.0 MM)")
                    .font(TacticalTheme.monoFont(size: 8))
                    .foregroundColor(TacticalTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Selector de Blanco de Superficie
            HStack {
                Text("BLANCO:")
                    .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                    .foregroundColor(TacticalTheme.textMuted)

                Text(viewModel.selectedSurfaceTarget)
                    .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                    .foregroundColor(Color.white)

                Spacer()

                Text(viewModel.isAuditModeActive ? "MODO AUDITORÍA" : "LÍNEA BASE (REFERENCIA)")
                    .font(TacticalTheme.monoFont(size: 8, weight: .black))
                    .foregroundColor(viewModel.isAuditModeActive ? TacticalTheme.alertRed : TacticalTheme.neonGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background((viewModel.isAuditModeActive ? TacticalTheme.alertRed : TacticalTheme.neonGreen).opacity(0.15))
                    .cornerRadius(3)
            }
            .padding(10)
            .tacticalCard()

            // Matriz Visual de Microrrelieve (10x10 Puntos de Muestreo de Malla)
            ZStack {
                Rectangle()
                    .fill(TacticalTheme.pureBlack)
                    .overlay(
                        GridPatternShape(spacing: 16)
                            .stroke(TacticalTheme.neonGreen.opacity(0.1), lineWidth: 1)
                    )

                if viewModel.isScanningSurface {
                    VStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: TacticalTheme.neonGreen))
                        Text("RECONSTRUYENDO NUBE DE PUNTOS SUB-MILIMÉTRICA...")
                            .font(TacticalTheme.monoFont(size: 9))
                            .foregroundColor(TacticalTheme.neonGreenDimmed)
                    }
                } else {
                    // Malla de relieve
                    VStack(spacing: 3) {
                        ForEach(0..<10, id: \.self) { y in
                            HStack(spacing: 3) {
                                ForEach(0..<10, id: \.self) { x in
                                    let idx = y * 10 + x
                                    if idx < viewModel.currentSurfaceProfile.points.count {
                                        let point = viewModel.currentSurfaceProfile.points[idx]
                                        SurfacePointCell(point: point, isAudited: viewModel.isAuditModeActive)
                                    }
                                }
                            }
                        }
                    }
                    .padding(8)
                }
            }
            .frame(height: 240)
            .tacticalHUDFrame(color: viewModel.isAuditModeActive && viewModel.detectedAlterationsCount > 0 ? TacticalTheme.alertRed : TacticalTheme.neonGreen)
            .tacticalCard()

            // Métricas de Desviación y Score de Integridad
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DESVIACIÓN MÁX:")
                        .font(TacticalTheme.monoFont(size: 8))
                        .foregroundColor(TacticalTheme.textMuted)
                    Text("\(String(format: "%.2f", viewModel.currentSurfaceProfile.maxDeviationMM)) mm")
                        .font(TacticalTheme.monoFont(size: 12, weight: .black))
                        .foregroundColor(viewModel.currentSurfaceProfile.maxDeviationMM >= 0.8 ? TacticalTheme.alertRed : TacticalTheme.neonGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .tacticalCard()

                VStack(alignment: .leading, spacing: 2) {
                    Text("PUNTOS CRÍTICOS:")
                        .font(TacticalTheme.monoFont(size: 8))
                        .foregroundColor(TacticalTheme.textMuted)
                    Text("\(viewModel.detectedAlterationsCount)")
                        .font(TacticalTheme.monoFont(size: 12, weight: .black))
                        .foregroundColor(viewModel.detectedAlterationsCount > 0 ? TacticalTheme.alertRed : TacticalTheme.neonGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .tacticalCard()

                VStack(alignment: .leading, spacing: 2) {
                    Text("INTEGRIDAD:")
                        .font(TacticalTheme.monoFont(size: 8))
                        .foregroundColor(TacticalTheme.textMuted)
                    Text("\(Int(viewModel.currentSurfaceProfile.integrityScorePercent))%")
                        .font(TacticalTheme.monoFont(size: 12, weight: .black))
                        .foregroundColor(viewModel.currentSurfaceProfile.integrityScorePercent < 90 ? TacticalTheme.alertRed : TacticalTheme.neonGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .tacticalCard()
            }

            // Botones de Operación de Escaneo Táctico
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Button(action: {
                        viewModel.captureBaselineSurface()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.metering.matrix")
                            Text("1. GRABAR PERFIL BASE")
                        }
                        .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                        .foregroundColor(TacticalTheme.pureBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(TacticalTheme.neonGreen)
                        .cornerRadius(4)
                    }

                    Button(action: {
                        viewModel.performAuditComparison(simulateTampering: true)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass.circle.fill")
                            Text("2. AUDITAR (< 1MM)")
                        }
                        .font(TacticalTheme.monoFont(size: 10, weight: .black))
                        .foregroundColor(TacticalTheme.pureBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(TacticalTheme.alertRed)
                        .cornerRadius(4)
                    }
                }

                Button(action: {
                    viewModel.performAuditComparison(simulateTampering: false)
                }) {
                    Text("TEST AUDITORÍA SIN ALTERACIONES (100% LIMPIA)")
                        .font(TacticalTheme.monoFont(size: 9))
                        .foregroundColor(TacticalTheme.textMuted)
                }
            }
        }
    }
}

/// Celda gráfica que representa el micro-relieve del punto
struct SurfacePointCell: View {
    let point: SurfaceMicroPoint
    let isAudited: Bool

    var cellColor: Color {
        if !isAudited {
            return TacticalTheme.neonGreen.opacity(0.3)
        }

        let absD = abs(point.deltaMM)
        if absD >= 0.8 {
            return TacticalTheme.alertRed // Alteración crítica
        } else if absD >= 0.4 {
            return TacticalTheme.warningAmber // Rugosidad anómala
        } else {
            return TacticalTheme.neonGreen.opacity(0.35) // Conforme
        }
    }

    var body: some View {
        Rectangle()
            .fill(cellColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1.0, contentMode: .fit)
            .cornerRadius(1)
            .overlay(
                Rectangle()
                    .stroke(abs(point.deltaMM) >= 0.8 && isAudited ? Color.white : Color.clear, lineWidth: 1)
            )
    }
}
