//
//  ContentView 2.swift
//  PETro
//
//  Created by Діана Цісарук on 20.06.2026.
//
import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    Spacer()
                    Image("Parrot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 380, height: 380)
                        .offset(y: 40)

                    Spacer().frame(height: 32)

                    VStack(spacing: 8) {
                        Text("PETro")
                            .font(
                                .system(
                                    size: 56,
                                    weight: .black,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.primary)
                        
                        Text("A virtual parrot needs love too!")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .medium,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.primary)
                            .tracking(1)
                    }
                    Spacer().frame(height: 52)

                    VStack(spacing: 14) {

                        NavigationLink(destination: ARGameView()) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Play")
                                    .font(
                                        .system(
                                            size: 18,
                                            weight: .bold,
                                            design: .rounded
                                        )
                                    )
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.accentColor)
                            .cornerRadius(16)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 12, y: 5)
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: HelpView()) {
                            
                                HStack(spacing: 12) {
                                    Image(systemName: "list.bullet.rectangle")
                                        .font(
                                            .system(size: 18, weight: .semibold)
                                        )
                                    Text("Rules")
                                        .font(
                                            .system(
                                                size: 18,
                                                weight: .semibold,
                                                design: .rounded
                                            )
                                        )
                                }
                                .foregroundStyle(Color.accentColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.accentColor.opacity(0.15))
                                .cornerRadius(16)
                            
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 32)
                    Spacer().frame(height: 60)
                }
            }
        }
    }

    
}

#Preview {
    ContentView()
}
