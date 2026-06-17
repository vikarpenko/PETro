//
//  FoodDetector.swift
//  PETro
//
//  Created by Діана Цісарук on 17.06.2026.
//

import ARKit
import Foundation
import RealityKit

final class FoodDetector: NSObject, ARSessionDelegate {

    private weak var arView: ARView?
    private var pet: Pet?
    private var isProcessing = false

    private let detector = Detector()
    
    private var framesWithoutFood = 0
    private let framesBeforeStopEating = 8
    
    func setup(arView: ARView, pet: Pet?) {
        self.arView = arView
        self.pet = pet
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard !isProcessing, pet != nil,
            frame.timestamp.truncatingRemainder(dividingBy: 0.5) < 0.03
        else { return }
        guard detector.isReady else { return }

        let pixelBuffer = frame.capturedImage
        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            let detection = self.detector.detect(pixelBuffer: pixelBuffer)

            if let detectedFood = detection.first(where: {
                [
                    "bowl", "banana", "apple", "sandwich", "orange",
                    "broccoli", "carrot", "hot dog", "pizza", "donut",
                    "cake", "person"
                ].contains($0.label)
            }) {
                print("detected: \(detectedFood)")
                let screenPoint = CGPoint(
                    x: detectedFood.normRect.midX
                        * Double(self.arView?.bounds.width ?? 0),
                    y: detectedFood.normRect.midY
                        * Double(self.arView?.bounds.height ?? 0)
                )

                handleEating(point: screenPoint)
            } else {
                framesWithoutFood += 1
                if framesWithoutFood >= framesBeforeStopEating {
                    Task { @MainActor in self.pet?.stopEating() }
                }
                isProcessing = false
            }

        }

        func handleEating(point: CGPoint) {
            framesWithoutFood = 0
            guard let pet = pet, let arView = arView else { return }
            
            guard !pet.isEating else {
                isProcessing = false
                return
            }
            
            guard let hitResult = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .horizontal).first else {
                isProcessing = false
                return
            }
            let destination = Transform(matrix: hitResult.worldTransform)
            Task{ @MainActor in
                print("предмет найдено")
                await pet.goAndEat(dest: destination)
                self.isProcessing = false
            }
        
        }

    }
}
