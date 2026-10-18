import SwiftUI
import AVFoundation

/// Vista Representable para mostrar el fotograma procesado con CIFilter en tiempo real
public struct FilteredCameraStreamView: View {
    @ObservedObject var viewModel: VisualScannerViewModel
    @State private var currentImage: UIImage? = nil

    public init(viewModel: VisualScannerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black // Fondo negro absoluto táctico

                if let img = currentImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    // Vista simulada táctica mientras inicializa la cámara
                    VStack(spacing: 8) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 44, weight: .thin))
                            .foregroundColor(TacticalTheme.neonGreen.opacity(0.6))
                        Text("INICIALIZANDO SENSOR ÓPTICO CMOS...")
                            .font(TacticalTheme.monoFont(size: 10))
                            .foregroundColor(TacticalTheme.textMuted)
                    }
                }

                // Superposición de Puntos Calientes Infrarrojos Detectados
                ForEach(0..<viewModel.detectedInfraredHotspots.count, id: \.self) { idx in
                    let point = viewModel.detectedInfraredHotspots[idx]
                    IRTargetMarker(
                        point: CGPoint(
                            x: point.x * geo.size.width,
                            y: point.y * geo.size.height
                        ),
                        index: idx + 1
                    )
                }
            }
        }
        .onAppear {
            viewModel.onFrameProcessed = { image in
                self.currentImage = image
            }
        }
    }
}

/// Marcador HUD táctico sobre el destello infrarrojo detectado
struct IRTargetMarker: View {
    let point: CGPoint
    let index: Int

    var body: some View {
        ZStack {
            // Círculo exterior intermitente
            Circle()
                .stroke(TacticalTheme.alertRed, lineWidth: 2)
                .frame(width: 44, height: 44)
                .shadow(color: TacticalTheme.alertRed, radius: 6)

            // Cruz interna
            Rectangle()
                .fill(TacticalTheme.alertRed)
                .frame(width: 14, height: 2)
            Rectangle()
                .fill(TacticalTheme.alertRed)
                .frame(width: 2, height: 14)

            // Etiqueta de objetivo
            Text("IR-P\(index)")
                .font(TacticalTheme.monoFont(size: 9, weight: .black))
                .foregroundColor(TacticalTheme.alertRed)
                .offset(x: 28, y: -20)
        }
        .position(point)
    }
}
