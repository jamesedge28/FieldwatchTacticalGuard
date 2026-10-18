import SwiftUI

@main
struct FieldwatchTacticalGuardApp: App {
    init() {
        // Inicializar motor háptico y audio táctico en segundo plano
        _ = AudioHapticEngine.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .background(TacticalTheme.pureBlack)
        }
    }
}
