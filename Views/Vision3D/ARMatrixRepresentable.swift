import SwiftUI
import ARKit
import SceneKit

/// Representable que envuelve ARSCNView para renderizado Wireframe tipo Matrix y colocación de balizas 3D
public struct ARMatrixRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: Vision3DViewModel

    public init(viewModel: Vision3DViewModel) {
        self.viewModel = viewModel
    }

    public func makeUIView(context: Context) -> ARSCNView {
        guard ARWorldTrackingConfiguration.isSupported else {
            return ARSCNView(frame: .zero)
        }
        let view = viewModel.sceneView

        // Agregar gesto táctil para apuntar y disparar el análisis de reflectancia láser
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)

        return view
    }

    public func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Las actualizaciones se gestionan directamente a través del ViewModel
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    public class Coordinator: NSObject {
        let viewModel: Vision3DViewModel

        init(viewModel: Vision3DViewModel) {
            self.viewModel = viewModel
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            viewModel.analyzeLiDAROpticalBounce(at: location)
        }
    }
}
