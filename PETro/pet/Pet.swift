//  Created by Viktoria Karpenko on 02.06.2026.
import Foundation
import RealityKit
import UIKit

final class Pet: Entity {
    enum AnimationState {
        case fly
        case eat
        case idle
        case rise
        case land
        case trick
        case circleFly
        
        var startTime: TimeInterval {
            switch self {
            case .fly: return 0.0
            case .eat: return 1.8361666666666667
            case .idle: return 6.97638888888889
            case .rise: return 16.768331908988764
            case .land: return 18.674204269662922
            case .trick: return 21.54098090786517
            case .circleFly: return 26.121442114606744
            }
        }
        
        var duration: TimeInterval {
            switch self {
            case .fly: return 1.4253888888888888
            case .eat: return 5.140222222222223
            case .idle: return 3.0
            case .rise: return 1.9058562728089887
            case .land: return 2.866792193483146
            case .trick: return 4.580461206741573
            case .circleFly: return 7.4792847671910115
            }
        }
    }

    private let modelContainer = Entity()
    private var parrotModel: Entity?

    private var currentState: AnimationState?
    private var isMoving = false
    
    required init() {
        super.init()
        self.addChild(modelContainer)
        setup()
    }

    private func setup() {
        if let parrot = try? Entity.load(named: "parrot_actions.usdz") {
            parrot.scale = [0.5, 0.5, 0.5]
            self.parrotModel = parrot
            modelContainer.addChild(parrot)
            play(.idle)
        } else {
            let mesh = MeshResource.generateBox(size: 0.1)
            let material = SimpleMaterial(color: .purple, isMetallic: false)
            let model = ModelComponent(mesh: mesh, materials: [material])
            self.components.set(model)
        }
    }

    func play(_ state: AnimationState) {
        guard state != currentState else { return }
        currentState = state

        guard let parrot = parrotModel,
            let fullAnim = parrot.availableAnimations.first
        else { return }

        let totalDuration = state.startTime + state.duration
        let trimmedDefinition = fullAnim.definition.trimmed(
            duration: totalDuration
        )

        let idleView = AnimationView(
            source: trimmedDefinition,
            offset: state.startTime
        )

        if let clip = try? AnimationResource.generate(with: idleView) {
            switch state {
            case .rise, .land, .trick:
                parrot.playAnimation(clip)
            default:
                parrot.playAnimation(clip.repeat())
            }
        }
    }

    @MainActor
    func fly(to destination: Transform) async {
        guard !isMoving else { return }
        
        isMoving = true
        
        let currentPosition = position(relativeTo: nil)
        let offset = destination.translation - currentPosition

        let distance = length(offset)
        let flightDuration = TimeInterval(distance / 0.8)
        let direction = SIMD3<Float>(offset.x, 0, offset.z)

        var target = Transform(
            scale: scale,
            rotation: orientation(relativeTo: nil),
            translation: destination.translation
        )

        if length(direction) > 0.001 {
            let modelRotation: Float = .pi / 2
            let yaw = atan2(-direction.x, -direction.z) + modelRotation
            target.rotation = simd_quatf(angle: yaw, axis: [0, 1, 0])
        }

        play(.rise)
        await waitForAnimation(AnimationState.rise.duration)
        
        play(.fly)
        move(to: target, relativeTo: nil, duration: flightDuration, timingFunction: .easeInOut)
        
        await waitForAnimation(flightDuration)
        
        play(.land)
        await waitForAnimation(AnimationState.land.duration)
        
        play(.idle)
        isMoving = false
    }
    
    private func waitForAnimation(_ duration: TimeInterval) async {
        let nanoseconds = UInt64(duration * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}
