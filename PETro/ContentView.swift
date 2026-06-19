//  Created by Viktoria Karpenko on 28.05.2026.
import SwiftUI

struct ContentView: View {
    
    @State private var currentAnimation: Pet.AnimationState = .idle
    @State private var showHelp = false
    
    var body: some View {
        ARViewContainer(animationState: $currentAnimation)
            .ignoresSafeArea()
            .overlay(alignment: .topTrailing) {
                Button {
                    showHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 34))
                        .foregroundStyle(.primary)
                        .background(.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(.top, 10)
                .padding(.trailing, 24)
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
    }
}

#Preview {
    ContentView()
}
