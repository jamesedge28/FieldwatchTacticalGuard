import SwiftUI

/// Submódulo: Dispositivos Parásitos (Cotejo Volumétrico LiDAR vs Patrones de Fábrica)
public struct ParasiteCatalogView: View {
    @ObservedObject var viewModel: PhysicalIntegrityViewModel

    public var body: some View {
        VStack(spacing: 14) {
            // Cabecera del Submódulo
            VStack(alignment: .leading, spacing: 3) {
                Text("COTEJO VOLUMÉTRICO DE DISPOSITIVOS PARÁSITOS")
                    .font(TacticalTheme.monoFont(size: 11, weight: .bold))
                    .foregroundColor(TacticalTheme.neonGreen)

                Text("DETECCIÓN DE HARDWARE ESPÍA OCULTO EN CARGADORES Y ENCHUFES")
                    .font(TacticalTheme.monoFont(size: 8))
                    .foregroundColor(TacticalTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Selector de Componente Estándar de Fábrica
            VStack(alignment: .leading, spacing: 4) {
                Text("PATRÓN DE FÁBRICA DE REFERENCIA:")
                    .font(TacticalTheme.monoFont(size: 8, weight: .bold))
                    .foregroundColor(TacticalTheme.textMuted)

                Menu {
                    ForEach(viewModel.factoryProfiles) { profile in
                        Button(action: {
                            viewModel.selectFactoryProfile(profile)
                        }) {
                            Text("\(profile.name) [\(profile.category)]")
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "cube.box.fill")
                            .foregroundColor(TacticalTheme.neonGreen)
                        Text(viewModel.selectedFactoryProfile.name)
                            .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                            .foregroundColor(Color.white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(TacticalTheme.textMuted)
                    }
                    .padding(10)
                    .tacticalCard()
                }
            }

            // Vulnerabilidad Común de Espionaje
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 12))
                    .foregroundColor(TacticalTheme.warningAmber)

                VStack(alignment: .leading, spacing: 2) {
                    Text("VECTOR DE INFILTRACIÓN TÍPICO:")
                        .font(TacticalTheme.monoFont(size: 8, weight: .bold))
                        .foregroundColor(TacticalTheme.warningAmber)
                    Text(viewModel.selectedFactoryProfile.commonSpyVulnerability)
                        .font(TacticalTheme.monoFont(size: 8))
                        .foregroundColor(Color.white.opacity(0.85))
                }
            }
            .padding(10)
            .tacticalCard(borderColor: TacticalTheme.warningAmber.opacity(0.4))

            // Calibrador LiDAR 3D (Medición de Dimensiones Reales)
            VStack(spacing: 8) {
                HStack {
                    Text("CALIBRADOR LIDAR (MEDIDAS FÍSICAS):")
                        .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                        .foregroundColor(TacticalTheme.neonGreen)
                    Spacer()
                    Text("TOLERANCIA: ±\(String(format: "%.0f", viewModel.selectedFactoryProfile.tolerancePercent))%")
                        .font(TacticalTheme.monoFont(size: 8))
                        .foregroundColor(TacticalTheme.textMuted)
                }

                // Slider Ancho
                dimensionSlider(
                    label: "ANCHO",
                    value: $viewModel.scannedWidthMM,
                    factoryVal: viewModel.selectedFactoryProfile.standardWidthMM,
                    range: (viewModel.selectedFactoryProfile.standardWidthMM * 0.7)...(viewModel.selectedFactoryProfile.standardWidthMM * 1.4)
                )

                // Slider Alto
                dimensionSlider(
                    label: "ALTO",
                    value: $viewModel.scannedHeightMM,
                    factoryVal: viewModel.selectedFactoryProfile.standardHeightMM,
                    range: (viewModel.selectedFactoryProfile.standardHeightMM * 0.7)...(viewModel.selectedFactoryProfile.standardHeightMM * 1.4)
                )

                // Slider Profundidad
                dimensionSlider(
                    label: "PROF.",
                    value: $viewModel.scannedDepthMM,
                    factoryVal: viewModel.selectedFactoryProfile.standardDepthMM,
                    range: (viewModel.selectedFactoryProfile.standardDepthMM * 0.7)...(viewModel.selectedFactoryProfile.standardDepthMM * 1.5)
                )
            }
            .padding(12)
            .tacticalCard()

            // Evaluación Volumétrica y Veredicto de Contrainteligencia
            if let audit = viewModel.activeAudit {
                VStack(spacing: 8) {
                    HStack {
                        Text("EVALUACIÓN VOLUMÉTRICA:")
                            .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                            .foregroundColor(TacticalTheme.textMuted)
                        Spacer()
                        Text(audit.riskLevel.rawValue)
                            .font(TacticalTheme.monoFont(size: 9, weight: .black))
                            .foregroundColor(riskColor(audit.riskLevel))
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("VOL. NOMINAL:")
                                .font(TacticalTheme.monoFont(size: 8))
                                .foregroundColor(TacticalTheme.textMuted)
                            Text("\(String(format: "%.1f", audit.profile.standardVolumeCm3)) cm³")
                                .font(TacticalTheme.monoFont(size: 11, weight: .bold))
                                .foregroundColor(Color.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("VOL. MEDIDO:")
                                .font(TacticalTheme.monoFont(size: 8))
                                .foregroundColor(TacticalTheme.textMuted)
                            Text("\(String(format: "%.1f", audit.measuredVolumeCm3)) cm³")
                                .font(TacticalTheme.monoFont(size: 11, weight: .bold))
                                .foregroundColor(Color.white)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("DELTA:")
                                .font(TacticalTheme.monoFont(size: 8))
                                .foregroundColor(TacticalTheme.textMuted)
                            Text("\(audit.volumeDeltaPercent >= 0 ? "+" : "")\(String(format: "%.1f", audit.volumeDeltaPercent))%")
                                .font(TacticalTheme.monoFont(size: 13, weight: .black))
                                .foregroundColor(riskColor(audit.riskLevel))
                        }
                    }

                    // Barra de Desviación Volumétrica
                    TacticalGaugeBar(
                        value: min(1.0, max(0.0, (audit.volumeDeltaPercent + 10.0) / 30.0)),
                        label: "EXCESO VOLUMÉTRICO SOSPECHOSO",
                        detailText: "\(String(format: "%.1f", audit.volumeDeltaPercent))%",
                        alertThreshold: 0.6
                    )
                }
                .padding(12)
                .tacticalCard(
                    borderColor: riskColor(audit.riskLevel).opacity(0.6),
                    backgroundColor: TacticalTheme.cardDarkGray
                )
            }

            // Acciones Tácticas
            HStack(spacing: 8) {
                Button(action: {
                    viewModel.applySpyParasiteSimulation()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "ladybug.fill")
                        Text("SIMULAR PARÁSITO (+22% VOL)")
                    }
                    .font(TacticalTheme.monoFont(size: 9, weight: .bold))
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

                Button(action: {
                    viewModel.saveCurrentAuditToHistory()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("REGISTRAR")
                    }
                    .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                    .foregroundColor(TacticalTheme.pureBlack)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(TacticalTheme.neonGreen)
                    .cornerRadius(4)
                }
            }
        }
    }

    private func dimensionSlider(label: String, value: Binding<Double>, factoryVal: Double, range: ClosedRange<Double>) -> some View {
        VStack(spacing: 2) {
            HStack {
                Text(label)
                    .font(TacticalTheme.monoFont(size: 8, weight: .bold))
                    .foregroundColor(TacticalTheme.textMuted)
                Spacer()
                Text("\(String(format: "%.1f", value.wrappedValue)) mm")
                    .font(TacticalTheme.monoFont(size: 9, weight: .bold))
                    .foregroundColor(Color.white)
                Text("(STD: \(String(format: "%.1f", factoryVal)))")
                    .font(TacticalTheme.monoFont(size: 8))
                    .foregroundColor(TacticalTheme.textMuted)
            }

            Slider(value: value, in: range, step: 0.1) { _ in
                viewModel.evaluateCurrentHardwareAudit()
            }
            .accentColor(TacticalTheme.neonGreen)
        }
    }

    private func riskColor(_ risk: ParasiteRiskLevel) -> Color {
        switch risk {
        case .nominal: return TacticalTheme.neonGreen
        case .suspicious: return TacticalTheme.warningAmber
        case .criticalParasite: return TacticalTheme.alertRed
        }
    }
}
