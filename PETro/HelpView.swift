//  Created by Viktoria Karpenko on 19.06.2026.
import SwiftUI

struct HelpView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("How to use")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(.gray.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            
            HelpRow(
                icon: "hand.tap",
                title: "Place & move",
                detail: "Tap a surface to place your pet. Tap somewhere else and it flies over."
            )
            
            HelpRow(
                icon: "fork.knife",
                title: "Feed",
                detail: "Show the camera some food and the pet flies over to eat."
            )
            
            HelpRow(
                icon: "hand.raised",
                title: "Pet",
                detail: "Hold your hand over the pet for a couple of seconds to pet it."
            )
            
            HelpRow(
                icon: "waveform",
                title: "Repeats after you",
                detail: "Press and hold the parrot, say something, then release — it will repeat it back in a parrot voice."
            )
            
            HelpRow(
                icon: "zzz",
                title: "Don't bore it",
                detail: "Leave it alone too long and it'll dramatically drop dead from boredom - keep it company!"
            )
            
            Spacer()
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}

private struct HelpRow: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    HelpView()
}
