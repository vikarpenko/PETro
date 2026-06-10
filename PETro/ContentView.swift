//  Created by Viktoria Karpenko on 28.05.2026.

import SwiftUI

struct ContentView: View {
    
    @State private var currentAnimation: Pet.AnimationState = .idle
    
    var body: some View {
        ZStack {
            ARViewContainer(animationState: $currentAnimation)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: { currentAnimation = .idle }) {
                        Text("Idle")
                            .padding()
                            .background(currentAnimation == .idle ? Color.blue : Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    
                    Button(action: { currentAnimation = .fly }) {
                        Text("Fly")
                            .padding()
                            .background(currentAnimation == .fly ? Color.blue : Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    
                    Button(action: { currentAnimation = .eat }) {
                        Text("Eat")
                            .padding()
                            .background(currentAnimation == .eat ? Color.blue : Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    ContentView()
}
