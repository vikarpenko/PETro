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

        if ARWorldTrackingConfiguration.supportsFrameSemantics(
            .personSegmentationWithDepth
        ) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
            arView.environment.sceneUnderstanding.options.insert(.occlusion)
        }

        arView.session.run(configuration)

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )

        arView.addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.5
        arView.addGestureRecognizer(longPress)

        tap.require(toFail: longPress)

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
        private let handDetector = HandDetector()
        private let voiceEngine = VoiceEngine()

        private var isProcessingVoice = false
        private var recordingTask: Task<Void, Never>?

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard !isProcessingVoice else { return }
            
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
                    await pet.move(to: destination)
                }
            } else {
                let newPet = Pet()
                let anchor = AnchorEntity(world: hitResult.worldTransform)
                anchor.addChild(newPet)
                arView.scene.addAnchor(anchor)
                pet = newPet

                foodDetector.setup(arView: arView, pet: newPet)
                arView.session.delegate = foodDetector

                handDetector.setup(arView: arView, pet: newPet)
            }
        }
        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard let pet = pet else { return }

            switch recognizer.state {
            case .began:
                guard !isProcessingVoice else { return }
                isProcessingVoice = true
                recordingTask = Task { @MainActor in
                    let granted = await voiceEngine.requestMicPermission()
                    guard granted else {
                        isProcessingVoice = false
                        return
                    }
                    guard !Task.isCancelled else {
                        isProcessingVoice = false
                        return
                    }
                    do {
                        try voiceEngine.startListening()
                    } catch {
                        isProcessingVoice = false
                    }
                }

            case .ended, .cancelled:
                guard isProcessingVoice else { return }
                
                recordingTask?.cancel()
                recordingTask = nil
                
                if voiceEngine.state == .listening {
                    Task { @MainActor in
                        voiceEngine.stopListening()
                        let estimatedDuration: TimeInterval = 3.0
                        await pet.reactToMimic(soundDuration: estimatedDuration) {
                            [weak self] in
                            self?.voiceEngine.playBackAsParrot(
                                pitchCents: 700,
                                rate: 1.15
                            )
                        }
                        isProcessingVoice = false
                    }
                } else {
                    voiceEngine.cancel()
                    isProcessingVoice = false
                }

            default:
                break
            }
        }
    }

}
