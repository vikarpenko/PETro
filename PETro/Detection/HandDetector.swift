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
    private let requiredPettingDuration: TimeInterval = 2
    private let handLostTimeout: TimeInterval = 1
    
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
              let frame = arView?.session.currentFrame,
              frame.timestamp.truncatingRemainder(dividingBy: 0.5) < 0.03
        else { return }
        
        isProcessing = true
        let cameraImage = frame.capturedImage
        let frameTimestamp = frame.timestamp
        
        Task {
            let handDetected = await detectHand(in: cameraImage)
            updatePetting(handDetected: handDetected, at: frameTimestamp)
            isProcessing = false
        }
    }
    
    private func detectHand(in cameraImage: CVPixelBuffer) async -> Bool {
        return await Task.detached {
            let request = VNDetectHumanHandPoseRequest()
            request.maximumHandCount = 1
            
            let imageHandler = VNImageRequestHandler(
                cvPixelBuffer: cameraImage,
                orientation: .right
            )
            
            try? imageHandler.perform([request])
            return request.results?.isEmpty == false
        }.value
    }
    
    private func updatePetting(handDetected: Bool, at timestamp: TimeInterval) {
        if handDetected {
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
