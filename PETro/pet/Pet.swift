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
    
    required init() {
        super.init()
        self.addChild(modelContainer)
        setup()
    }
    
    private func setup() {
        if let parrot = try? Entity.load(named: "parrot.usdz") {
            parrot.scale = [3, 3, 3]
            
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
}
