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
                    Text("Coins: \(viewModel.playerState.coins)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(12)
                        .background(.black.opacity(0.5))
                        .cornerRadius(10)
                    
                    Spacer()
                    
                    Text("High Score: \(viewModel.playerState.highScore)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(12)
                        .background(.black.opacity(0.5))
                        .cornerRadius(10)
                }
                .padding()
                .foregroundColor(.white)
                
                Spacer()
                
                // 4. The bottom UI section changes based on game state.
                if viewModel.isRoundActive {
                    // Show the current score during the round
                    Text("Score: \(viewModel.currentRoundScore)")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .padding()
                        .background(.black.opacity(0.5))
                        .cornerRadius(15)
                } else {
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
                }
            }
        }
    }
}
