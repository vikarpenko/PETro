//  Created by Viktoria Karpenko on 19.06.2026.
import Foundation
import RealityKit
import ARKit
import Vision
import Combine

@MainActor
final class HandDetector {
    
    private var arView: ARView?
    private var pet: Pet?
    
    private var isProcessing = false
    private var sceneSubscription: (any Cancellable)?
    
    private var handDetectedAt: TimeInterval?
    private var handLastDetectedAt: TimeInterval?
    private let handLostTimeout: TimeInterval = 1
    private let requiredPettingDuration: TimeInterval = 1
    private let pettingRadius: CGFloat = 200
    
    func setup(arView: ARView, pet: Pet) {
        self.arView = arView
        self.pet = pet
        
        sceneSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            MainActor.assumeIsolated { self?.onUpdate() }
        }
        
        print(" --- hand detector ready")
    }
    
    func handlePetting() {
        guard let pet else { return }
        Task { await pet.reactToPetting() }
    }
    
    private func onUpdate() {
        guard !isProcessing,
              let arView,
              let frame = arView.session.currentFrame,
              frame.timestamp.truncatingRemainder(dividingBy: 0.5) < 0.03
        else { return }
        
        isProcessing = true
        let cameraImage = frame.capturedImage
        let frameTimestamp = frame.timestamp
        
        let arViewSize = arView.bounds.size
        let cameraImageSize = CGSize(
            width: CVPixelBufferGetHeight(cameraImage),
            height: CVPixelBufferGetWidth(cameraImage)
        )
        
        Task {
            let handPoint = await detectHand(in: cameraImage)
            
            var handOverPet = false
            if let handPoint, let petScreen = petScreenPoint() {
                let handScreen = screenPoint(for: handPoint,imageSize: cameraImageSize,viewport: arViewSize)
                handOverPet = hypot(handScreen.x - petScreen.x, handScreen.y - petScreen.y) < pettingRadius
            }
            // print(" --- hand over pet: ", handOverPet)
            
            updatePetting(handOverPet: handOverPet, at: frameTimestamp)
            isProcessing = false
        }
    }

    private func petScreenPoint() -> CGPoint? {
        guard let arView, let pet else { return nil }
        return arView.project(pet.position(relativeTo: nil))
    }

    private func screenPoint(for visionPoint: CGPoint, imageSize: CGSize, viewport: CGSize) -> CGPoint {
        let scale = max(viewport.width / imageSize.width, viewport.height / imageSize.height)
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        let xOffset = (scaledWidth - viewport.width) / 2
        let yOffset = (scaledHeight - viewport.height) / 2

        let x = visionPoint.x * scaledWidth - xOffset
        let y = (1 - visionPoint.y) * scaledHeight - yOffset
        return CGPoint(x: x, y: y)
    }
    
    private func detectHand(in cameraImage: CVPixelBuffer) async -> CGPoint? {
        return await Task.detached {
            let request = VNDetectHumanHandPoseRequest()
            request.maximumHandCount = 1
            
            let imageHandler = VNImageRequestHandler(
                cvPixelBuffer: cameraImage,
                orientation: .right
            )
            
            try? imageHandler.perform([request])
            
            guard let handObservation = request.results?.first,
                  let handCenterPoint = try? handObservation.recognizedPoint(.middleMCP),
                  handCenterPoint.confidence > 0.3
            else { return nil }
            
            return handCenterPoint.location
        }.value
    }
    
    private func updatePetting(handOverPet: Bool, at timestamp: TimeInterval) {
        if handOverPet {
            handLastDetectedAt = timestamp
            
            guard let detectedAt = handDetectedAt else {
                handDetectedAt = timestamp
                return
            }
            
            if timestamp - detectedAt >= requiredPettingDuration {
                handDetectedAt = nil
                handLastDetectedAt = nil
                print(" --- petted long enough")
                handlePetting()
            }
        } else if let lastDetectedAt = handLastDetectedAt,
                  timestamp - lastDetectedAt > handLostTimeout {
            handDetectedAt = nil
            handLastDetectedAt = nil
        }
    }
    
}
