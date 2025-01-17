//
//  TKEventManagerTests.swift
//  TrackKit
//
//  Created by Mahmoud HodaeeNia on 2025-01-17.
//


import XCTest
@testable import TrackKit

final class TKEventManagerTests: XCTestCase {

    var eventManager: TKEventManager!
    var mockStorage: MockStorage!

    override func setUp() {
        super.setUp()
        mockStorage = MockStorage()
        eventManager = TKEventManager(storage: mockStorage)
    }

    func testCanActivateEventWithValidConfig() async throws {
        let config = TKEventConfigBuilder()
            .setId("test_event")
            .setMinInterval(3600) // 1 hour
            .setMaxActivationCount(3)
            .setProbability(1.0) // Always eligible
            .build()

        let canActivate = try await eventManager.canActivateEvent(id: config.id, config: config)
        XCTAssertTrue(canActivate)
    }

    func testCanActivateEventFailsDueToInterval() async throws {
        let config = TKEventConfigBuilder()
            .setId("test_event")
            .setMinInterval(3600) // 1 hour
            .build()

        try await mockStorage.set(Date(), forKey: "trackkit_test_event_lastActivated")

        let canActivate = try await eventManager.canActivateEvent(id: config.id, config: config)
        XCTAssertFalse(canActivate)
    }

    func testMarkEventAsActivatedUpdatesStorage() async throws {
        let config = TKEventConfigBuilder()
            .setId("test_event")
            .build()

        try await eventManager.markEventAsActivated(id: config.id)

        let lastActivated: Date? = try await mockStorage.get(forKey: "trackkit_test_event_lastActivated")
        let activationCount: Int = try await mockStorage.get(forKey: "trackkit_test_event_activationCount") ?? 0

        XCTAssertNotNil(lastActivated)
        XCTAssertEqual(activationCount, 1)
    }

    func testGetEligibleEventsReturnsSortedResults() async throws {
        let event1 = TKEventConfigBuilder()
            .setId("event_1")
            .setPriority(1)
            .build()

        let event2 = TKEventConfigBuilder()
            .setId("event_2")
            .setPriority(2)
            .build()

        try await mockStorage.set(Date().addingTimeInterval(-3600), forKey: "event_1_lastActivated") // Make eligible
        try await mockStorage.set(Date().addingTimeInterval(-3600), forKey: "event_2_lastActivated") // Make eligible

        let eligibleEvents = try await eventManager.getEligibleEvents(configs: [event1, event2])
        XCTAssertEqual(eligibleEvents.count, 2)
        XCTAssertEqual(eligibleEvents[0].id, "event_2")
        XCTAssertEqual(eligibleEvents[1].id, "event_1")
    }
}

class MockStorage: TKEventStorage {
    private var storage: [String: Data] = [:]

    func set<T: Codable>(_ value: T, forKey key: String) async throws {
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(value)
        storage[key] = encoded
    }

    func get<T: Codable>(forKey key: String) async throws -> T? {
        guard let data = storage[key] else { return nil }
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    func remove(forKey key: String) throws {
        storage.removeValue(forKey: key)
    }
}
