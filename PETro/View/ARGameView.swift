//  Created by Viktoria Karpenko on 28.05.2026.
import SwiftUI

struct ARGameView: View {
    
    @State private var currentAnimation: Pet.AnimationState = .idle
    @State private var showHelp = false
    
    var body: some View {
        ARViewContainer(animationState: $currentAnimation)
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
    }
}

#Preview {
    ARGameView()
}
