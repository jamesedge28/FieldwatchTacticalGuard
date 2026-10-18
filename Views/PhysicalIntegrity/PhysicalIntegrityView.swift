import SwiftUI

/// Vista Principal de la Pestaña 5: "Integridad Física" (Análisis de Superficies y Parásitos)
public struct PhysicalIntegrityView: View {
    @StateObject private var viewModel = PhysicalIntegrityViewModel()

    public var body: some View {
        VStack(spacing: 0) {
            // Cabecera Táctica
            TacticalTopBar(
                title: "INTEGRIDAD FÍSICA Y HARDWARE",
                statusText: "ANÁLISIS ESTRUCTURAL",
                statusColor: TacticalTheme.neonGreen
            )

            // Selector Táctico de Submódulo
            Picker("Modo Integridad Física", selection: $viewModel.selectedMode) {
                ForEach(PhysicalIntegrityMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(TacticalTheme.pureBlack)

            // Contenido Dinámico de la Pestaña
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.selectedMode == .surfaceAudit {
                        SurfaceAuditView(viewModel: viewModel)
                    } else {
                        ParasiteCatalogView(viewModel: viewModel)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(TacticalTheme.pureBlack)
        }
        .background(TacticalTheme.pureBlack)
    }
}
