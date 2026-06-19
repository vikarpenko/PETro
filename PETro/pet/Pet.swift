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
        case petting
        
        var startTime: TimeInterval {
            switch self {
            case .fly: return 0.0
            case .eat: return 1.8361666666666667
            case .idle: return 6.97638888888889
            case .rise: return 16.768331908988764
            case .land: return 18.674204269662922
            case .trick: return 21.54098090786517
            case .circleFly: return 26.121442114606744
            case .petting: return 13.03
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
            case .petting: return 4.0
            }
        }
    }
    
    enum PetState {
        case idle
        case moving
        case eating
        case beingPetted
    }
    
    private let modelContainer = Entity()
    private var parrotModel: Entity?
    
    private var currentAnimation: AnimationState?
    private var behaviorTask: Task<Void, Never>?
    
    private(set) var state: PetState = .idle
    
    private let boredomDelay: TimeInterval = 15
    private let speed: Float = 0.8
    
    required init() {
        super.init()
        self.addChild(modelContainer)
        Task{
            await setup()
        }
    }
    
    @MainActor
    private func setup() async {
        if let parrot = try? await Entity(named: "parrot_actions.usdz") {
            parrot.scale = [0.5, 0.5, 0.5]
            self.parrotModel = parrot
            modelContainer.addChild(parrot)
            startIdleBehavior()
        } else {
            let mesh = MeshResource.generateBox(size: 0.1)
            let material = SimpleMaterial(color: .purple, isMetallic: false)
            let model = ModelComponent(mesh: mesh, materials: [material])
            self.components.set(model)
        }
    }
    
    func play(_ animation: AnimationState) {
        guard animation != currentAnimation else { return }
        currentAnimation = animation
        
        guard let parrot = parrotModel,
              let fullAnim = parrot.availableAnimations.first
        else { return }
        
        let view = AnimationView(
            source: fullAnim.definition,
            trimStart: animation.startTime,
            trimEnd: animation.startTime + animation.duration
        )
        
        if let clip = try? AnimationResource.generate(with: view) {
            switch animation {
            case .rise, .land, .trick:
                parrot.playAnimation(clip)
            default:
                parrot.playAnimation(clip.repeat())
            }
        }
    }
    
    @MainActor
    func move(to destination: Transform) async {
        guard state == .idle || state == .eating else { return }
        await flyTo(destination)
        startIdleBehavior()
    }
    
    @MainActor
    func goAndEat(dest: Transform) async {
        guard state == .idle else { return }
        await flyTo(dest)
        play(.eat)
        state = .eating
    }
    
    @MainActor
    func stopEating() {
        guard state == .eating else { return }
        state = .idle
        startIdleBehavior()
    }
    
    @MainActor
    func reactToPetting() async {
        guard state == .idle || state == .eating else { return }
        
        state = .beingPetted
        behaviorTask?.cancel()
        
        play(.petting)
        await waitForAnimation(AnimationState.petting.duration)
        
        state = .idle
        startIdleBehavior()
    }
    
    private func waitForAnimation(_ duration: TimeInterval) async {
        try? await Task.sleep(for: .seconds(duration))
    }
    
    private func flyTo(_ destination: Transform) async {
        state = .moving
        behaviorTask?.cancel()
        
        let currentPosition = position(relativeTo: nil)
        let offset = destination.translation - currentPosition
        
        let distance = length(offset)
        let flightDuration = TimeInterval(distance / speed)
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
        
        state = .idle
    }
    
    private func startIdleBehavior() {
        behaviorTask?.cancel()
        
        behaviorTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            play(.idle)
            await waitForAnimation(boredomDelay)

            if Task.isCancelled { return }

            play(.trick)
        }
    }
    
}
