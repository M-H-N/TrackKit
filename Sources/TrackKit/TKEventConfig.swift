//
//  TKEventConfig.swift
//  TrackKit
//
//  Created by Mahmoud HodaeeNia on 2025-01-17.
//

import Foundation

/// Configuration for an event in TrackKit.
open class TKEventConfig {
    /// Unique identifier for the event.
    public let id: String

    /// Minimum interval (in seconds) between consecutive activations of the event.
    public let minInterval: TimeInterval

    /// Expiration date for the event. If `nil`, the event never expires.
    public let expirationDate: Date?

    /// Maximum number of times the event can be activated. If `nil`, there is no limit.
    public let maxActivationCount: Int?

    /// Priority of the event. Higher values indicate higher priority.
    public let priority: Int

    /// Probability (between 0.0 and 1.0) that the event will be activated.
    /// - 1.0: Always eligible.
    /// - 0.0: Never eligible.
    public let probability: Double

    /// Additional metadata for the event (e.g., title, description, or related data).
    public let metadata: [String: Any]?

    /// List of event IDs that must be activated before this event becomes eligible.
    public let dependencies: [String]

    public init(
        id: String,
        minInterval: TimeInterval,
        expirationDate: Date? = nil,
        maxActivationCount: Int? = nil,
        priority: Int = 0,
        probability: Double = 1.0,
        metadata: [String: Any]? = nil,
        dependencies: [String] = []
    ) {
        self.id = id
        self.minInterval = minInterval
        self.expirationDate = expirationDate
        self.maxActivationCount = maxActivationCount
        self.priority = priority
        self.probability = probability
        self.metadata = metadata
        self.dependencies = dependencies
    }
}
