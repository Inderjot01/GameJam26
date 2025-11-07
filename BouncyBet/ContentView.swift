//
//  ContentView.swift
//  BouncyBet
//
//  This is the main SwiftUI view. It hosts the SpriteView
//  and overlays the UI on top of it.
//

import SwiftUI
import SpriteKit
import Combine  // ADD THIS IMPORT (optional but good practice)

struct ContentView: View {
    
    // 1. Creates the ViewModel, the app's "source of truth".
    //    @StateObject ensures it lives for the life of the view.
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            
            // 2. The SpriteKit game scene, hosted in SwiftUI.
            //    It fills the entire background.
            SpriteView(scene: viewModel.gameScene)
                .ignoresSafeArea()
            
            // 3. The SwiftUI UI overlay
            VStack {

                HStack {
                    // 1. Coins (left)
                    VStack {
                        Text("COINS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(viewModel.playerState.coins)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(width: 110, height: 60) // Fixed size
                    .background(.black.opacity(0.5))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    // 2. Score (middle)
                    VStack {
                        Text("SCORE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(viewModel.currentRoundScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(width: 110, height: 60) // Fixed size
                    .background(.black.opacity(0.5))
                    .cornerRadius(10)

                    Spacer()
                    
                    // 3. High Score (right)
                    VStack {
                        Text("HIGH SCORE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(viewModel.playerState.highScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(width: 110, height: 60) // Fixed size
                    .background(.black.opacity(0.5))
                    .cornerRadius(10)
                }
                .padding()
                .foregroundColor(.white)
                Spacer()
                                
                // 4. The bottom UI section
                
                // ADD THIS LINE
                if !viewModel.isRoundActive {
                    
                    // Show the "Enter Round" button when idle
                    Button(action: viewModel.placeWager) {
                        Text("Enter Round (\(GameConfig.wagerAmount) Coins)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(viewModel.canAffordWager ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!viewModel.canAffordWager) // Disable if not enough coins
                    .padding()
                    
                // ADD THIS LINE
                }

            }
        }
    }
}
