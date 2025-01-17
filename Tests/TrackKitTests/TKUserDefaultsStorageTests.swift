//
//  TKUserDefaultsStorageTests.swift
//  TrackKit
//
//  Created by Mahmoud HodaeeNia on 2025-01-17.
//


import XCTest
@testable import TrackKit

final class TKUserDefaultsStorageTests: XCTestCase {

    var storage: TKUserDefaultsStorage!

    override func setUp() {
        super.setUp()
        storage = TKUserDefaultsStorage(defaults: UserDefaults(suiteName: "test_suite")!)
    }

    override func tearDown() {
        super.tearDown()
        UserDefaults().removePersistentDomain(forName: "test_suite")
    }

    func testSetAndGetCodableValue() async throws {
        let testDate = Date()
        try await storage.set(testDate, forKey: "test_key")

        let retrievedDate: Date? = try await storage.get(forKey: "test_key")
        XCTAssertEqual(retrievedDate, testDate)
    }

    func testRemoveValue() async throws {
        let testValue = "Hello, TrackKit!"
        try await storage.set(testValue, forKey: "test_key")

        try await storage.remove(forKey: "test_key")
        let retrievedValue: String? = try await storage.get(forKey: "test_key")

        XCTAssertNil(retrievedValue)
    }
}
