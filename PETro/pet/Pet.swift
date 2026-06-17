//  Created by Viktoria Karpenko on 02.06.2026.
import Foundation
import UIKit
import RealityKit

final class Pet: Entity {
    
    enum AnimationState {
        case fly
        case eat
        case idle
        
        var startTime: TimeInterval {
            switch self {
            case .fly:  return 0.0
            case .eat:  return 1.8361666666666667
            case .idle: return 6.97638888888889
            }
        }
        
        var duration: TimeInterval {
            switch self {
            case .fly:  return 1.4253888888888888
            case .eat:  return 5.140222222222223
            case .idle: return 3.0
            }
        }
    }
    
    private let modelContainer = Entity()
    private var parrotModel: Entity?

    private var currentState: AnimationState?
    
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
            
        } else{
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
              let fullAnim = parrot.availableAnimations.first else { return }
        
        let totalDuration = state.startTime + state.duration
        let trimmedDefinition = fullAnim.definition.trimmed(duration: totalDuration)
        
        let idleView = AnimationView(
            source: trimmedDefinition,
            offset: state.startTime
        )
        
        if let clip = try? AnimationResource.generate(with: idleView) {
            parrot.playAnimation(clip.repeat())
        }
    }
    
    func fly(to destination: Transform) {
        let currentPosition = position(relativeTo: nil)
        let offset = destination.translation - currentPosition
        
        let distance = length(offset)
        let duration = TimeInterval(distance / 0.8)
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

        play(.fly)
        move(to: target, relativeTo: nil, duration: duration, timingFunction: .easeInOut)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.play(.idle)
        }
    }
}
