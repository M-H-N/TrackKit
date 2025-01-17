//
//  TKUserDefaultsStorage.swift
//  TrackKit
//
//  Created by Mahmoud HodaeeNia on 2025-01-17.
//

import Foundation

/// Default implementation of `TKEventStorage` using `UserDefaults`.
public class TKUserDefaultsStorage: TKEventStorage {
    private let defaults: UserDefaults

    /// Initializes a new `TKUserDefaultsStorage` instance.
    /// - Parameters:
    ///   - defaults: The `UserDefaults` instance to use. Defaults to `.standard`.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Stores a value in `UserDefaults`.
    /// - Parameters:
    ///   - value: The value to store, conforming to `Codable`.
    ///   - key: The key under which to store the value.
    /// - Throws: `TKEventError.serializationFailed` if encoding fails.
    public func set<T: Codable>(_ value: T, forKey key: String) async throws {
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(value)
            defaults.set(encoded, forKey: key)
        } catch {
            throw TKEventError.serializationFailed("Failed to encode value for key: \(key)")
        }
    }

    /// Retrieves a value from `UserDefaults`.
    /// - Parameters:
    ///   - key: The key for the value to retrieve.
    /// - Returns: The value, or `nil` if it doesn't exist.
    /// - Throws: `TKEventError.valueNotFound` if the value does not exist.
    /// - Throws: `TKEventError.serializationFailed` if decoding fails.
    public func get<T: Codable>(forKey key: String) async throws -> T? {
        guard let data = defaults.data(forKey: key) else {
//            throw TKEventError.valueNotFound("Value for key '\(key)' not found in UserDefaults")
            return nil
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw TKEventError.serializationFailed("Failed to decode value for key: \(key)")
        }
    }

    /// Removes a value from `UserDefaults`.
    /// - Parameters:
    ///   - key: The key for the value to remove.
    /// - Throws: `TKEventError.valueNotFound` if the value does not exist.
    public func remove(forKey key: String) async throws {
        guard defaults.object(forKey: key) != nil else {
            throw TKEventError.valueNotFound("Value for key '\(key)' not found in UserDefaults")
        }
        defaults.removeObject(forKey: key)
    }
}
