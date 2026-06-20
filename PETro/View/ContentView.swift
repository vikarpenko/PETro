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
                Color(red: 0.08, green: 0.22, blue: 0.18)
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    Spacer()
                    Image("parrot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 380, height: 380)
                        .cornerRadius(30)

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
                            .foregroundStyle(.mint)

                        Text("Віртуальний папуга теж хоче любові!")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .medium,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.white)
                            .tracking(1)
                    }
                    Spacer().frame(height: 52)

                    VStack(spacing: 14) {

                        NavigationLink(destination: ARGameView()) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Почати гру")
                                    .font(
                                        .system(
                                            size: 18,
                                            weight: .bold,
                                            design: .rounded
                                        )
                                    )
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.mint)
                            .cornerRadius(16)
                        }

                        NavigationLink(destination: HelpView()) {
                            
                                HStack(spacing: 12) {
                                    Image(systemName: "list.bullet.rectangle")
                                        .font(
                                            .system(size: 18, weight: .semibold)
                                        )
                                    Text("Правила")
                                        .font(
                                            .system(
                                                size: 18,
                                                weight: .semibold,
                                                design: .rounded
                                            )
                                        )
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(.white.opacity(0.10))
                                .cornerRadius(16)
                            
                        }
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
