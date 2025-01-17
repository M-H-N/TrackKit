//
//  TKEventConfigTests.swift
//  TrackKit
//
//  Created by Mahmoud HodaeeNia on 2025-01-17.
//

import XCTest
@testable import TrackKit

final class TKEventConfigTests: XCTestCase {

    func testEventConfigBuilderCreatesValidConfig() {
        let config = TKEventConfigBuilder()
            .setId("test_event")
            .setMinInterval(3600) // 1 hour
            .setExpirationDate(Date().addingTimeInterval(86400)) // 1 day
            .setMaxActivationCount(5)
            .setPriority(10)
            .setProbability(0.9)
            .setMetadata(["key": "value"])
            .build()
        
        XCTAssertEqual(config.id, "test_event")
        XCTAssertEqual(config.minInterval, 3600)
        XCTAssertNotNil(config.expirationDate)
        XCTAssertEqual(config.maxActivationCount, 5)
        XCTAssertEqual(config.priority, 10)
        XCTAssertEqual(config.probability, 0.9)
        XCTAssertEqual(config.metadata?["key"] as? String, "value")
    }

    func testEventConfigBuilderThrowsErrorForInvalidProbability() {
        let configHighProbability = TKEventConfigBuilder()
            .setId("test_event")
            .setProbability(2.4) // More than 1
            .setMetadata(["key": "value"])
            .build()

        XCTAssertEqual(configHighProbability.probability, 1.0)

        let configLowProbability = TKEventConfigBuilder()
            .setId("test_event")
            .setProbability(-12) // Less than 0
            .setMetadata(["key": "value"])
            .build()

        XCTAssertEqual(configLowProbability.probability, .zero)
    }
}
