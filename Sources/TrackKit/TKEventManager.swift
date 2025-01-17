//
//  TKEventManager.swift
//  TrackKit
//
//  Created by Mahmoud HodaeeNia on 2025-01-17.
//

import Foundation
import Combine

/// Represents an event activation in TrackKit
public struct TKEventActivation {
    /// The ID of the activated event
    public let eventId: String
    /// The date when the event was activated
    public let activationDate: Date
    /// The total number of times this event has been activated
    public let activationCount: Int
}

/// Manages the logic and state for activating events in TrackKit with error handling.
open class TKEventManager {
    let storage: TKEventStorage
    
    /// Publisher that emits event activations when they occur
    public let eventActivations = PassthroughSubject<TKEventActivation, Never>()

    /// Initializes a new `TKEventManager` with a custom asynchronous storage implementation.
    public init(storage: TKEventStorage = TKUserDefaultsStorage()) {
        self.storage = storage
    }

    /// Determines if an event is eligible for activation based on its configuration and custom conditions.
    open func canActivateEvent(
        config: TKEventConfig,
        customCondition: (() throws -> Bool)? = nil
    ) async throws -> Bool {
        if let expiration = config.expirationDate, Date() > expiration {
            return false
        }

        let id = config.id

        let activationCount: Int = try await storage.get(forKey: self.getKey(forId: id, andPostFix: "activationCount")) ?? 0
        if let maxCount = config.maxActivationCount, activationCount >= maxCount {
            return false
        }

        if let lastActivated: Date = try await storage.get(forKey: self.getKey(forId: id, andPostFix: "lastActivated")),
           Date().timeIntervalSince(lastActivated) < config.minInterval {
            return false
        }

        // Check dependencies
        for dependencyId in config.dependencies {
            let dependencyActivationCount: Int = try await storage.get(forKey: self.getKey(forId: dependencyId, andPostFix: "activationCount")) ?? 0
            if dependencyActivationCount == 0 {
                return false
            }
        }

        let randomValue = Double.random(in: 0...1)
        if randomValue > config.probability {
            return false
        }

        if let customCondition = customCondition {
            return try customCondition()
        }

        return true
    }

    /// Marks an event as activated, updating its last activation date and incrementing its activation count.
    open func markEventAsActivated(id: String, atDate date: Date = Date()) async throws {
        try await storage.set(date, forKey: self.getKey(forId: id, andPostFix: "lastActivated"))
        var activationCount: Int = try await storage.get(forKey: self.getKey(forId: id, andPostFix: "activationCount")) ?? 0
        activationCount += 1
        try await storage.set(activationCount, forKey: self.getKey(forId: id, andPostFix: "activationCount"))
        
        // Emit the activation event
        let activation = TKEventActivation(
            eventId: id,
            activationDate: date,
            activationCount: activationCount
        )
        eventActivations.send(activation)
    }

    /// Resets the state of an event, clearing its last activation date and activation count.
    open func resetEvent(id: String) async throws {
        try await storage.remove(forKey: self.getKey(forId: id, andPostFix: "lastActivated"))
        try await storage.remove(forKey: self.getKey(forId: id, andPostFix: "activationCount"))
    }

    /// Retrieves all eligible events from a list of configurations, sorted by priority.
    open func getEligibleEvents(
        configs: [TKEventConfig],
        customConditions: [String: () throws -> Bool] = [:]
    ) async throws -> [TKEventConfig] {
        var eligibleEvents: [TKEventConfig] = []

        for config in configs {
            let isEligible = try await canActivateEvent(
                config: config,
                customCondition: customConditions[config.id]
            )
            if isEligible {
                eligibleEvents.append(config)
            }
        }

        return eligibleEvents.sorted(by: { $0.priority > $1.priority })
    }

    open func getKey(forId id: String, andPostFix postFix: String) -> String {
        "tk.\(id).\(postFix)"
    }
}
