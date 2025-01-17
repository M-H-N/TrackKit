//
//  TKEventManagerProbabilityTests.swift
//  TrackKit
//
//  Created by Mahmoud HodaeeNia on 2025-01-17.
//


import XCTest
@testable import TrackKit

final class TKEventManagerProbabilityTests: XCTestCase {

    var eventManager: TKEventManager!
    var mockStorage: MockStorage!

    override func setUp() {
        super.setUp()
        mockStorage = MockStorage()
        eventManager = TKEventManager(storage: mockStorage)
    }

    func testProbabilityAffectsActivation() async throws {
        let config = TKEventConfigBuilder()
            .setId("test_event")
            .setMinInterval(0) // No interval restriction
            .setProbability(0.3) // 30% chance of activation
            .build()

        var successCount = 0
        let iterations = 10_000 // Run a large number of trials to test probability

        for _ in 0..<iterations {
            if try await eventManager.canActivateEvent(id: config.id, config: config) {
                successCount += 1
            }
        }

        let actualProbability = Double(successCount) / Double(iterations)

        // Allow a small margin of error for statistical variation
        let expectedProbability = 0.3
        let marginOfError = 0.02
        XCTAssert(
            abs(actualProbability - expectedProbability) <= marginOfError,
            "Expected probability \(expectedProbability), but got \(actualProbability)"
        )
    }
}
