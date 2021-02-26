//
//  SplitEventsManagerTest.swift
//  Split_Tests
//
//  Created by Sebastian Arrubia on 4/24/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class SplitEventsManagerTest: XCTestCase {
    
    let expectationTimeOut = 20.0
    var shouldStop: Bool!
    var maxExecutionTime: Int!
    let intervalExecutionTime = 1
    
    override func setUp() {
        shouldStop = false
        maxExecutionTime = currentTimestamp() + 10
    }
    
    override func tearDown() {
    }
    
    func testSdkReady() {
        
        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.start()
        
        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsAreReady)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsAreReady)
        
        let expectation = XCTestExpectation(description: "SDK Readky triggered")
        DispatchQueue.global().async {
            while !self.shouldStop {
                sleep(UInt32(self.intervalExecutionTime))
                self.maxExecutionTime -= self.intervalExecutionTime
                if eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady) || self.currentTimestamp() > self.maxExecutionTime {
                    self.shouldStop = true;
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: expectationTimeOut)
        
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out shouldn't be triggered");
    }

    func testSdkReadyFromCacheAndReady() {

        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.start()

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsLoadedFromCache)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsLoadedFromCache)

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsAreReady)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsAreReady)

        let expectation = XCTestExpectation(description: "SDK Readky from cache triggered")
        DispatchQueue.global().async {
            while !self.shouldStop {
                sleep(UInt32(self.intervalExecutionTime))
                self.maxExecutionTime -= self.intervalExecutionTime
                if eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady) || self.currentTimestamp() > self.maxExecutionTime {
                    self.shouldStop = true;
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyFromCache), "SDK Ready should from cache be triggered");
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out shouldn't be triggered");
    }

    func testSdkReadyFromCacheAndReadyTimeout() {

        let config: SplitClientConfig = SplitClientConfig()
        config.sdkReadyTimeOut = 1000
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.start()

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsLoadedFromCache)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsLoadedFromCache)

        let expectation = XCTestExpectation(description: "SDK Readky from cache triggered")
        DispatchQueue.global().async {
            while !self.shouldStop {
                sleep(UInt32(self.intervalExecutionTime))
                self.maxExecutionTime -= self.intervalExecutionTime
                if eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady) || self.currentTimestamp() > self.maxExecutionTime {
                    self.shouldStop = true;
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyFromCache), "SDK Ready should from cache be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready should not be triggered");
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out should be triggered");
    }
    
    func testSdkReadyTimeOut() {
        
        let config: SplitClientConfig = SplitClientConfig()
        config.sdkReadyTimeOut = 5000
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.start()
        
        let expectation = XCTestExpectation(description: "SDK Readky Timeout triggered")
        DispatchQueue.global().async {
            while !self.shouldStop {
                sleep(UInt32(self.intervalExecutionTime))
                self.maxExecutionTime -= self.intervalExecutionTime
                if eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady) || self.currentTimestamp() > self.maxExecutionTime {
                    self.shouldStop = true;
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: expectationTimeOut)
        
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out should be triggered")
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready shouldn't be triggered")
        
    }
    
    func testSdkReadyAndReadyTimeOut() {
        
        let config: SplitClientConfig = SplitClientConfig()
        config.sdkReadyTimeOut = 5000
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.start()
        
        let expectationTimeout = XCTestExpectation(description: "SDK Readky triggered")
        DispatchQueue.global().async {
            while !self.shouldStop {
                sleep(UInt32(self.intervalExecutionTime))
                self.maxExecutionTime -= self.intervalExecutionTime
                if eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady) || self.currentTimestamp() > self.maxExecutionTime {
                    self.shouldStop = true;
                    expectationTimeout.fulfill()
                }
            }
        }
        wait(for: [expectationTimeout], timeout: expectationTimeOut)
        
        //At this line timeout has been reached
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out should be triggered")
        
        //But if after timeout event, the Splits and MySegments are ready, SDK_READY should be triggered
        shouldStop = false
        maxExecutionTime = currentTimestamp() + 10
        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsAreReady)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsAreReady)
        
        let expectationReady = XCTestExpectation(description: "SDK Readky triggered")
        DispatchQueue.global().async {
            while !self.shouldStop {
                sleep(UInt32(self.intervalExecutionTime))
                self.maxExecutionTime -= self.intervalExecutionTime
                if eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady) || self.currentTimestamp() > self.maxExecutionTime {
                    self.shouldStop = true;
                    expectationReady.fulfill()
                }
            }
        }
        wait(for: [expectationReady], timeout: expectationTimeOut)
        
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready should be triggered");
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out should be triggered")
        
    }
    
    // MARK: Helpers
    func currentTimestamp() -> Int {
        return Int(Date().unixTimestamp())
    }
}
