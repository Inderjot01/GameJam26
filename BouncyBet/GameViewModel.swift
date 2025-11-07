//
//  GameViewModel.swift
//  BouncyBet
//
//  This class is the "single source of truth" for the application.
//  It's an ObservableObject, so SwiftUI views can subscribe to its changes.
//  It bridges the gap between the SwiftUI UI and the SpriteKit GameScene.
//

import Foundation
import SpriteKit
import Combine  // ADD THIS IMPORT

class GameViewModel: ObservableObject {
    
    // MARK: - Published Properties
    // SwiftUI views will automatically update when these change.
    
    @Published var playerState: PlayerState
    @Published var isRoundActive: Bool = false
    @Published var currentRoundScore: Int = 0
    
    // MARK: - Properties
    
    /// A reference to the SpriteKit scene.
    let gameScene: GameScene

    // MARK: - Initializer
    
    init() {
        // 1. Load the player's saved state
        let loadedState = PersistenceManager.shared.load()
        self.playerState = loadedState
        
        // 2. Create the GameScene
        // We set the size here (e.g., iPhone 14 Pro)
        // .aspectFill will scale it to other devices.
        self.gameScene = GameScene(size: CGSize(width: 393, height: 852))
        self.gameScene.scaleMode = .aspectFill
        
        // 3. CRITICAL: Pass a reference of this ViewModel TO the GameScene.
        // This is the "delegate" pattern that allows the scene to call
        // methods on the ViewModel (e.g., roundDidEnd).
        self.gameScene.viewModel = self
    }
    
    // MARK: - Intents (Methods called by UI)
    
    /// Called by the SwiftUI "Enter Round" button.
    func placeWager() {
        guard playerState.coins >= GameConfig.wagerAmount, !isRoundActive else {
            return // Not enough coins, or round already in progress
        }
        
        // 1. Deduct the wager
        playerState.coins -= GameConfig.wagerAmount
        
        // 2. Update state
        isRoundActive = true
        currentRoundScore = 0
        
        // 3. Tell the GameScene to set up the new field
        gameScene.prepareNewRound()
    }
    
    // MARK: - Callbacks (Methods called by GameScene)
    
    /// Called by the GameScene when the 10-second timer expires.
    func roundDidEnd(score: Int) {
        // 1. Calculate payout
        let payout = score * GameConfig.payoutMultiplier
        
        // 2. Add payout to total
        playerState.coins += payout
        
        // 3. Check for high score
        if score > playerState.highScore {
            playerState.highScore = score
        }
        
        // 4. Update state
        isRoundActive = false
        currentRoundScore = score
        
        // 5. Save the new player state to disk
        PersistenceManager.shared.save(playerState)
    }
    
    /// Called by the GameScene on every collision to update the UI in real-time.
    func scoreDidChange(newScore: Int) {
        // Use `DispatchQueue.main.async` because this is called
        // from the SpriteKit physics loop (a background thread).
        // UI updates MUST happen on the main thread.
        DispatchQueue.main.async {
            self.currentRoundScore = newScore
        }
    }
}

// A helper extension for the view
extension GameViewModel {
    var canAffordWager: Bool {
        playerState.coins >= GameConfig.wagerAmount
    }
}
