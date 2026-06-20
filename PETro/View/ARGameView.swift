//  Created by Viktoria Karpenko on 28.05.2026.
import SwiftUI

struct ARGameView: View {
    
    @State private var currentAnimation: Pet.AnimationState = .idle
    
    var body: some View {
        ARViewContainer(animationState: $currentAnimation)
            .ignoresSafeArea()
    }
}

#Preview {
    ARGameView()
}
