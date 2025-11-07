//
//  DataModels.swift
//  BouncyBet
//
//  Defines all pure data structures for the game.
//

import Foundation
import CoreGraphics // For CGVector

// MARK: - Player State

/// Holds all persistent data for the player.
/// Codable allows it to be saved to UserDefaults easily.
struct PlayerState: Codable {
    var coins: Int
    var highScore: Int

    /// Provides a default state for new players.
    static var `default`: PlayerState {
        PlayerState(coins: 100, highScore: 0)
    }
}

// MARK: - Game Configuration

/// Contains static constants for game balancing and physics.
/// Centralizing these here makes the game easy to tune.
struct GameConfig {
    static let projectileLifespan: TimeInterval = 10.0
    
    // Wager and Payout
    static let wagerAmount: Int = 10
    static let payoutMultiplier: Int = 1 // Payout = Score * Multiplier
    
    // Scoring - Balanced for fair gameplay
    static let obstaclePoints: Int = 5      // Reduced from 10
    static let rewardPoints: Int = 50       // Reduced from 100
    static let hazardPoints: Int = -50      // Same penalty
}

// MARK: - Field Object Definitions

/// Defines the type of object on the field.
enum ObjectType: CaseIterable {
    case obstacle // Standard peg
    case reward   // Positive points
    case hazard   // Negative points
}

/// A pure data model representing a single object in the field.
struct ObjectData {
    let id: UUID = UUID()
    let type: ObjectType
    let points: Int
    let textureName: String
    
    /// Factory method to create a random object with balanced distribution
    static func createRandom() -> ObjectData {
        let random = Int.random(in: 0..<100)
        
        if random < 50 {
            // 50% chance for obstacles
            return ObjectData(type: .obstacle, points: GameConfig.obstaclePoints, textureName: "obstacle")
        } else if random < 80 {
            // 30% chance for rewards
            return ObjectData(type: .reward, points: GameConfig.rewardPoints, textureName: "reward")
        } else {
            // 20% chance for hazards
            return ObjectData(type: .hazard, points: GameConfig.hazardPoints, textureName: "hazard")
        }
    }
}

// MARK: - Physics Categories

/// Defines all physics categories using UInt32 bitmasks.
/// This struct is the brain of the collision detection system.
struct PhysicsCategory {
    static let none:            UInt32 = 0
    static let projectile:      UInt32 = 0x1 << 0 // (1)
    static let obstacle:        UInt32 = 0x1 << 1 // (2)
    static let reward:          UInt32 = 0x1 << 2 // (4)
    static let hazard:          UInt32 = 0x1 << 3 // (8)
    static let worldBoundary:   UInt32 = 0x1 << 4 // (16)
}
