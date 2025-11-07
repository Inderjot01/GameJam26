//
//  PersistenceManager.swift
//  BouncyBet
//
//  Manages saving and loading game data (PlayerState).
//  Uses a Singleton pattern and a @UserDefault property wrapper.
//

import Foundation

/// A singleton class to manage all data persistence.
class PersistenceManager {
    static let shared = PersistenceManager()
    
    // This property wrapper handles all the logic for
    // encoding/decoding the PlayerState struct to/from UserDefaults.
    @UserDefault(key: "playerState", defaultValue: PlayerState.default)
    var playerState: PlayerState

    private init() {}
    
    func save(_ state: PlayerState) {
        self.playerState = state
    }

    func load() -> PlayerState {
        return self.playerState
    }
}

// MARK: - @UserDefault Property Wrapper

/// A generic property wrapper for saving/loading Codable types in UserDefaults.
@propertyWrapper
struct UserDefault<T: Codable> {
    let key: String
    let defaultValue: T
    let storage: UserDefaults

    init(key: String, defaultValue: T, storage: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }

    var wrappedValue: T {
        get {
            // Read and decode the data
            guard let data = storage.data(forKey: key) else {
                return defaultValue
            }
            let decoder = JSONDecoder()
            return (try? decoder.decode(T.self, from: data)) ?? defaultValue
        }
        set {
            // Encode and save the data
            let encoder = JSONEncoder()
            if let encodedData = try? encoder.encode(newValue) {
                storage.set(encodedData, forKey: key)
            }
        }
    }
}
