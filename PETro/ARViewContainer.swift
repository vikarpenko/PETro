//  Created by Viktoria Karpenko on 30.05.2026.
import Foundation
import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    
    @Binding var animationState: Pet.AnimationState
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
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
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let screenPoint = recognizer.location(in: arView)
            
            guard let hitResult = arView.raycast(
                from: screenPoint,
                allowing: .estimatedPlane,
                alignment: .horizontal
            ).first else { return }

            let hitY = hitResult.worldTransform.columns.3.y
            let cameraY = arView.cameraTransform.translation.y
            guard hitY < cameraY else { return }

            if let pet = pet {
                let destination = Transform(matrix: hitResult.worldTransform)
                pet.fly(to: destination)
            } else {
                let newPet = Pet()
                let anchor = AnchorEntity(world: hitResult.worldTransform)
                anchor.addChild(newPet)
                arView.scene.addAnchor(anchor)
                pet = newPet
            }
        }
    }
}
