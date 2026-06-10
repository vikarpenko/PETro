//  Created by Viktoria Karpenko on 02.06.2026.
import Foundation
import UIKit
import RealityKit

final class Pet: Entity, HasModel {
    
    required init() {
        super.init()
        if let parrot = try? Entity.load(named: "parrot.usdz") {
            parrot.scale = [0.005, 0.005, 0.005]
            if let animation = parrot.availableAnimations.first {
                parrot.playAnimation(animation.repeat())
            }
            self.addChild(parrot)
        } else{
            let mesh = MeshResource.generateBox(size: 0.1)
            let material = SimpleMaterial(color: .purple, isMetallic: false)
            let model = ModelComponent(mesh: mesh, materials: [material])
            self.components.set(model)
            
        }
    }
}
