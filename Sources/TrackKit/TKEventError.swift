//
//  TKEventError.swift
//  TrackKit
//
//  Created by Mahmoud HodaeeNia on 2025-01-17.
//


/// Errors that can occur in TrackKit's event management.
public enum TKEventError: Error, Equatable {
    /// Thrown when an operation attempts to retrieve a non-existent value.
    case valueNotFound(String)

    /// Thrown when encoding or decoding a value fails.
    case serializationFailed(String)

    /// Thrown when a probability value is out of bounds.
    case invalidProbability(String)
}
