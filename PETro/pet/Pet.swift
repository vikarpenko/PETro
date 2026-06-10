//  Created by Viktoria Karpenko on 02.06.2026.
import Foundation
import UIKit
import RealityKit

final class Pet: Entity, HasModel {
    
    required init() {
        super.init()
        // purple cube for start
        if let parrot = try? Entity.load(named: "Art.scnassets/pareot.usdz") {
            self.addChild(parrot)
        } else{
            let mesh = MeshResource.generateBox(size: 0.1)
            let material = SimpleMaterial(color: .purple, isMetallic: false)
            let model = ModelComponent(mesh: mesh, materials: [material])
            self.components.set(model)
            
        }
    }
}
