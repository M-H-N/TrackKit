import XCTest
import Combine
@testable import TrackKit

final class TKEventDependencyTests: XCTestCase {
    var eventManager: TKEventManager!
    var storage: TKUserDefaultsStorage!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        storage = TKUserDefaultsStorage()
        eventManager = TKEventManager(storage: storage)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        eventManager = nil
        storage = nil
        super.tearDown()
    }
    
    // MARK: - Dependency Tests
    
    func testEventWithNoDependenciesIsEligible() async throws {
        let event = TKEventConfigBuilder()
            .setId("no_dependencies")
            .build()
            
        let isEligible = try await eventManager.canActivateEvent(id: event.id, config: event)
        XCTAssertTrue(isEligible, "Event with no dependencies should be eligible")
    }
    
    func testEventWithUnmetDependencyIsNotEligible() async throws {
        let event = TKEventConfigBuilder()
            .setId("dependent_event")
            .setDependencies([UUID().uuidString])
            .build()
            
        let isEligible = try await eventManager.canActivateEvent(id: event.id, config: event)
        XCTAssertFalse(isEligible, "Event with unmet dependency should not be eligible")
    }
    
    func testEventBecomesEligibleAfterDependencyMet() async throws {
        // Create and activate prerequisite event
        let prerequisite = TKEventConfigBuilder()
            .setId("prerequisite")
            .build()
        try await eventManager.markEventAsActivated(id: prerequisite.id)
        
        // Create dependent event
        let dependent = TKEventConfigBuilder()
            .setId("dependent_event")
            .setDependencies(["prerequisite"])
            .build()
            
        let isEligible = try await eventManager.canActivateEvent(id: dependent.id, config: dependent)
        XCTAssertTrue(isEligible, "Event should be eligible after dependency is met")
    }
    
    func testEventWithMultipleDependencies() async throws {
        // Create dependent event requiring both prerequisites
        let dependent = TKEventConfigBuilder()
            .setId("dependent_event")
            .setDependencies(["prereq1", "prereq2"])
            .build()
            
        // Initially should not be eligible
        var isEligible = try await eventManager.canActivateEvent(id: dependent.id, config: dependent)
        XCTAssertFalse(isEligible, "Event should not be eligible when no prerequisites are met")
        
        // Activate first prerequisite
        try await eventManager.markEventAsActivated(id: "prereq1")
        isEligible = try await eventManager.canActivateEvent(id: dependent.id, config: dependent)
        XCTAssertFalse(isEligible, "Event should not be eligible when only one prerequisite is met")
        
        // Activate second prerequisite
        try await eventManager.markEventAsActivated(id: "prereq2")
        isEligible = try await eventManager.canActivateEvent(id: dependent.id, config: dependent)
        XCTAssertTrue(isEligible, "Event should be eligible when all prerequisites are met")
    }
    
    // MARK: - Publisher Tests
    
    func testEventActivationPublisher() async throws {
        let expectation = XCTestExpectation(description: "Event activation published")
        let testEventId = "test_event"
        
        eventManager.eventActivations
            .filter { $0.eventId == testEventId }
            .sink { activation in
                XCTAssertEqual(activation.eventId, testEventId)
                XCTAssertEqual(activation.activationCount, 1)
                XCTAssertLessThanOrEqual(activation.activationDate.timeIntervalSinceNow, 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let event = TKEventConfigBuilder()
            .setId(testEventId)
            .build()
            
        try await eventManager.markEventAsActivated(id: event.id)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testMultipleEventActivationsPublished() async throws {
        let expectation = XCTestExpectation(description: "Multiple event activations published")
        expectation.expectedFulfillmentCount = 3
        
        let testEventId = "multiple_activations"
        var receivedActivationCounts: Set<Int> = []
        
        eventManager.eventActivations
            .filter { $0.eventId == testEventId }
            .sink { activation in
                receivedActivationCounts.insert(activation.activationCount)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let event = TKEventConfigBuilder()
            .setId(testEventId)
            .build()
        
        // Activate event multiple times
        try await eventManager.markEventAsActivated(id: event.id)
        try await eventManager.markEventAsActivated(id: event.id)
        try await eventManager.markEventAsActivated(id: event.id)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedActivationCounts, Set([1, 2, 3]), "Should receive activations with counts 1, 2, and 3")
    }
    
    func testEventActivationWithMetadata() async throws {
        let expectation = XCTestExpectation(description: "Event activation with metadata published")
        let testEventId = "metadata_event"
        
        eventManager.eventActivations
            .filter { $0.eventId == testEventId }
            .sink { activation in
                XCTAssertEqual(activation.eventId, testEventId)
                XCTAssertGreaterThan(activation.activationCount, 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let event = TKEventConfigBuilder()
            .setId(testEventId)
            .setMetadata(["test": "value"])
            .build()
            
        try await eventManager.markEventAsActivated(id: event.id)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
} 
