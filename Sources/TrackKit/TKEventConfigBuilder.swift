//
//  TKEventConfigBuilder.swift
//  TrackKit
//
//  Created by Mahmoud HodaeeNia on 2025-01-17.
//

import Foundation

/// A builder for creating `TKEventConfig` instances in TrackKit.
public final class TKEventConfigBuilder {
    private var id: String?
    private var minInterval: TimeInterval = 0
    private var expirationDate: Date?
    private var maxActivationCount: Int?
    private var priority: Int = 0
    private var probability: Double = 1.0
    private var metadata: [String: Any]?
    private var dependencies: [String] = []

    public init() {}

    /// Sets the unique identifier for the event.
    @discardableResult
    public func setId(_ id: String) -> Self {
        self.id = id
        return self
    }

    /// Sets the minimum interval (in seconds) between consecutive activations of the event.
    public func setMinInterval(_ interval: TimeInterval) -> TKEventConfigBuilder {
        self.minInterval = interval
        return self
    }

    /// Sets the expiration date for the event. If `nil`, the event will never expire.
    public func setExpirationDate(_ date: Date?) -> TKEventConfigBuilder {
        self.expirationDate = date
        return self
    }

    /// Sets the maximum number of times the event can be activated. If `nil`, there is no limit.
    public func setMaxActivationCount(_ count: Int?) -> TKEventConfigBuilder {
        self.maxActivationCount = count
        return self
    }

    /// Sets the priority of the event. Higher values indicate higher priority.
    public func setPriority(_ priority: Int) -> TKEventConfigBuilder {
        self.priority = priority
        return self
    }

    /// Sets the probability of the event being activated.
    public func setProbability(_ probability: Double) -> TKEventConfigBuilder {
        self.probability = max(min(probability, 1.0), .zero)
        return self
    }

    /// Sets additional metadata for the event (e.g., title, description, or related data).
    @discardableResult
    public func setMetadata(_ metadata: [String: Any]?) -> Self {
        self.metadata = metadata
        return self
    }

    @discardableResult
    public func setDependencies(_ dependencies: [String]) -> Self {
        self.dependencies = dependencies
        return self
    }

    /// Builds and returns a `TKEventConfig` instance. Throws an error if required fields are missing.
    public func build() -> TKEventConfig {
        guard let id = id else {
            fatalError("TKEventConfig requires an id")
        }
        return TKEventConfig(
            id: id,
            minInterval: minInterval,
            expirationDate: expirationDate,
            maxActivationCount: maxActivationCount,
            priority: priority,
            probability: probability,
            metadata: metadata,
            dependencies: dependencies
        )
    }
}
