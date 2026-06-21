//
//  FoodDetector.swift
//  PETro
//
//  Created by Діана Цісарук on 17.06.2026.
//

import ARKit
import Foundation
import RealityKit

@MainActor
final class FoodDetector: NSObject, ARSessionDelegate {

    private weak var arView: ARView?
    private var pet: Pet?
    private var isProcessing = false

    private let detector = Detector()

    private var framesWithoutFood = 0
    private let framesBeforeStopEating = 8

    private let foodOptions = [
        "bowl", "banana", "apple", "sandwich", "orange",
        "broccoli", "carrot", "hot dog", "pizza", "donut",
        "cake",
    ]

    func setup(arView: ARView, pet: Pet?) {
        self.arView = arView
        self.pet = pet
    }

    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        Task { @MainActor in
            guard !isProcessing, pet != nil,
                frame.timestamp.truncatingRemainder(dividingBy: 0.5) < 0.03
            else { return }
            guard detector.isReady else { return }
            isProcessing = true

            let pixelBuffer = frame.capturedImage
            let detection = detector.detect(pixelBuffer: pixelBuffer)

            if let detectedFood = detection.first(where: {
                foodOptions.contains($0.label)
            }) {
                print("detected: \(detectedFood)")

                let viewport = self.arView?.bounds.size ?? .zero
                
                let imageCenter = CGPoint(
                    x: detectedFood.normRect.midX,
                    y: detectedFood.normRect.midY
                )
                
                let viewNormalized = imageCenter.applying(
                    frame.displayTransform(for: .portrait, viewportSize: viewport)
                )
                
                let screenPoint = CGPoint(
                    x: viewNormalized.x * viewport.width,
                    y: viewNormalized.y * viewport.height
                )

                handleEating(point: screenPoint)
            } else {
                framesWithoutFood += 1
                if framesWithoutFood >= framesBeforeStopEating {
                    self.pet?.stopEating()
                }
                isProcessing = false
            }
        }
    }

    func handleEating(point: CGPoint) {
        framesWithoutFood = 0
        guard let pet = pet, let arView = arView else {
            isProcessing = false
            return
        }

        guard pet.state == .idle else {
            isProcessing = false
            return
        }

        guard
            let hitResult = arView.raycast(
                from: point,
                allowing: .estimatedPlane,
                alignment: .horizontal
            ).first
        else {
            isProcessing = false
            return
        }
        let destination = Transform(matrix: hitResult.worldTransform)
        Task {
            defer { self.isProcessing = false }
            print("предмет найдено")
            await pet.goAndEat(dest: destination)
        }

    }
}
