import SwiftUI

/// Enumeración de las 5 Pestañas Tácticas Obligatorias
public enum TacticalTab: Int, CaseIterable, Identifiable {
    case signals = 0
    case visualScanner = 1
    case vision3D = 2
    case sentinel = 3
    case physicalIntegrity = 4

    public var id: Int { self.rawValue }

    public var title: String {
        switch self {
        case .signals: return "Señales"
        case .visualScanner: return "Escáner Visual"
        case .vision3D: return "Visión 3D"
        case .sentinel: return "Centinela"
        case .physicalIntegrity: return "Integridad Física"
        }
    }

    public var iconName: String {
        switch self {
        case .signals: return "antenna.radiowaves.left.and.right"
        case .visualScanner: return "camera.viewfinder"
        case .vision3D: return "cube.transparent"
        case .sentinel: return "lock.shield.fill"
        case .physicalIntegrity: return "ruler.fill"
        }
    }
}

/// ContentView Principal: Contenedor TabView estructurado exactamente en las 5 pestañas modulares requeridas
public struct ContentView: View {
    @State private var selectedTab: TacticalTab = .signals

    public init() {
        // Configuración estricta de la barra de navegación y pestañas de iOS para mantener el negro puro
        UITabBar.appearance().backgroundColor = UIColor.black
        UITabBar.appearance().barTintColor = UIColor.black
        UITabBar.appearance().unselectedItemTintColor = UIColor(red: 0.35, green: 0.35, blue: 0.38, alpha: 1.0)
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            TacticalTheme.pureBlack
                .edgesIgnoringSafeArea(.all)

            // Contenido Principal según la pestaña seleccionada
            TabView(selection: $selectedTab) {
                // 1. Tab "Señales" (Ecosistema Radiofrecuencia)
                SignalsView()
                    .tag(TacticalTab.signals)
                    .tabItem {
                        Label("Señales", systemImage: "antenna.radiowaves.left.and.right")
                    }

                // 2. Tab "Escáner Visual" (Detección Óptica e Infrarroja)
                VisualScannerView()
                    .tag(TacticalTab.visualScanner)
                    .tabItem {
                        Label("Escáner Visual", systemImage: "camera.viewfinder")
                    }

                // 3. Tab "Visión 3D" (LiDAR Espacial y Reflejos)
                Vision3DView()
                    .tag(TacticalTab.vision3D)
                    .tabItem {
                        Label("Visión 3D", systemImage: "cube.transparent")
                    }

                // 4. Tab "Centinela" (Alarma Volumétrica en Oscuridad)
                SentinelView()
                    .tag(TacticalTab.sentinel)
                    .tabItem {
                        Label("Centinela", systemImage: "lock.shield.fill")
                    }

                // 5. Tab "Integridad Física" (Análisis de Superficies y Parásitos)
                PhysicalIntegrityView()
                    .tag(TacticalTab.physicalIntegrity)
                    .tabItem {
                        Label("Integridad Física", systemImage: "ruler.fill")
                    }
            }
            .accentColor(TacticalTheme.neonGreen) // Elementos interactivos en verde neón #00FF00
        }
        .preferredColorScheme(.dark) // Forzar modo oscuro estricto a nivel de aplicación
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
