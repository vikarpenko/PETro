//  Created by Viktoria Karpenko on 30.05.2026.
import ARKit
import Foundation
import RealityKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {

    @Binding var animationState: Pet.AnimationState

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic

        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }

        arView.session.run(configuration)

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )

        arView.addGestureRecognizer(tap)
        context.coordinator.arView = arView

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.pet?.play(animationState)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {

        weak var arView: ARView?
        var pet: Pet?

        private let foodDetector = FoodDetector()

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let screenPoint = recognizer.location(in: arView)

            guard
                let hitResult = arView.raycast(
                    from: screenPoint,
                    allowing: .estimatedPlane,
                    alignment: .horizontal
                ).first
            else { return }

            let hitY = hitResult.worldTransform.columns.3.y
            let cameraY = arView.cameraTransform.translation.y
            guard hitY < cameraY else { return }

            if let pet = pet {
                let destination = Transform(matrix: hitResult.worldTransform)
                Task { @MainActor in
                    await pet.fly(to: destination)
                }
            } else {
                let newPet = Pet()
                let anchor = AnchorEntity(world: hitResult.worldTransform)
                anchor.addChild(newPet)
                arView.scene.addAnchor(anchor)
                pet = newPet

                foodDetector.setup(arView: arView, pet: newPet)
                arView.session.delegate = foodDetector
            }
        }
    }
}
