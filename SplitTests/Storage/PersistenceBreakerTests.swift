//
//  PersistenceBreakerTests.swift
//  SplitTests
//
//

import Foundation
import XCTest
@testable import Split

class PersistenceBreakerTests: XCTestCase {
    
    var breaker: PersistenceBreaker!
    
    override func setUp() {
        super.setUp()
    }
    
    func testInitiallyPersistenceIsEnabled() {
        breaker = DefaultPersistenceBreaker()
        
        XCTAssertTrue(breaker.isPersistenceEnabled,
                     "Persistence should be enabled initially")
    }
    
    func testDisablingPersistenceWorks() {
        breaker = DefaultPersistenceBreaker()
        
        breaker.disable()
        
        XCTAssertFalse(breaker.isPersistenceEnabled,
                      "Persistence should be disabled after calling disable()")
    }
    
    func testDisableIsIdempotent() {
        breaker = DefaultPersistenceBreaker()
        
        breaker.disable()
        breaker.disable()
        breaker.disable()
        
        XCTAssertFalse(breaker.isPersistenceEnabled,
                      "Multiple disable() calls should be idempotent")
    }
    
    func testThreadSafetyOfDisable() {
        breaker = DefaultPersistenceBreaker()
        let expectation = self.expectation(description: "Concurrent disable calls complete")
        expectation.expectedFulfillmentCount = 10
        
        for _ in 0..<10 {
            DispatchQueue.global().async {
                self.breaker.disable()
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
        XCTAssertFalse(breaker.isPersistenceEnabled,
                      "Concurrent disable() calls should be thread-safe")
    }
    
    func testThreadSafetyOfReads() {
        breaker = DefaultPersistenceBreaker()
        let expectation = self.expectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 100
        
        var readResults = [Bool]()
        let resultsQueue = DispatchQueue(label: "resultsQueue")
        
        // Many threads read while one disables
        for i in 0..<100 {
            DispatchQueue.global().async {
                if i == 50 {
                    // Disable in the middle
                    self.breaker.disable()
                }
                let result = self.breaker.isPersistenceEnabled
                resultsQueue.sync {
                    readResults.append(result)
                }
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(100, readResults.count,
                      "All reads should complete without crashes")
        XCTAssertFalse(breaker.isPersistenceEnabled,
                      "Final state should be disabled")
    }
}

