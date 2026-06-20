//  Created by Viktoria Karpenko on 28.05.2026.
import SwiftUI

struct ARGameView: View {

    @State private var currentAnimation: Pet.AnimationState = .idle
    @State private var showHelp = false
    @State private var isLoading = true

    var body: some View {
        ARViewContainer(
            animationState: $currentAnimation,
            isLoading: $isLoading
        )
        .overlay {
            if isLoading {
                ZStack {
                    Color("Background").ignoresSafeArea()

                    VStack(spacing: 20) {
                        ProgressView()
                            .controlSize(.large)

                        Text("Preparing your space...")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .semibold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.primary)
                    }
                }
                .transition(.opacity)
            }
        }
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
