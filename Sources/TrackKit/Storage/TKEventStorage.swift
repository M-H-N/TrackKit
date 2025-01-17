//
//  TKEventStorage.swift
//  TrackKit
//
//  Created by Mahmoud HodaeeNia on 2025-01-17.
//


/// Protocol defining the interface for a storage mechanism to be used by `TKEventManager`.
public protocol TKEventStorage {
    /// Stores a value in the storage.
    /// - Parameters:
    ///   - value: The value to store, conforming to `Codable`.
    ///   - key: The key under which to store the value.
    /// - Throws: `TKEventError.serializationFailed` if encoding fails.
    func set<T: Codable>(_ value: T, forKey key: String) async throws

    /// Retrieves a value from the storage.
    /// - Parameters:
    ///   - key: The key for the value to retrieve.
    /// - Returns: The value, or `nil` if it doesn't exist.
    /// - Throws: `TKEventError.valueNotFound` if the value does not exist.
    /// - Throws: `TKEventError.serializationFailed` if decoding fails.
    func get<T: Codable>(forKey key: String) async throws -> T?

    /// Removes a value from the storage.
    /// - Parameters:
    ///   - key: The key for the value to remove.
    /// - Throws: `TKEventError.valueNotFound` if the value does not exist.
    func remove(forKey key: String) async throws
}
