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

        let client = SplitClientStub()
        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.executorResources.client = client
        let updatedTask = TestTask(exp: nil)
        eventManager.register(event: .sdkUpdated, task: updatedTask)
        eventManager.start()
        
        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)
        ThreadUtils.delay(seconds: 0.2)
        
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
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkUpdated), "SDK Update shouldn't be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out shouldn't be triggered");
    }

    func testSdkReadyFromCacheAndReady() {

        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.start()

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsLoadedFromCache)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsLoadedFromCache)

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)

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
        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)
        
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

    func testSdkUpdateSplits() {
        let sdkUpdatedExp = XCTestExpectation()

        let client =  SplitClientStub()
        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.executorResources.client = client
        let updatedTask = sdkTask(exp: sdkUpdatedExp)
        eventManager.register(event: .sdkUpdated, task: updatedTask)
        eventManager.start()

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)

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
        wait(for: [expectation, sdkUpdatedExp], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready should be triggered");
        XCTAssertTrue(updatedTask.taskTriggered, "SDK Update should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out shouldn't be triggered");
    }

    func testSdkUpdateMySegments() {
        let sdkUpdatedExp = XCTestExpectation()

        let client =  SplitClientStub()
        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.executorResources.client = client
        let updatedTask = sdkTask(exp: sdkUpdatedExp)
        eventManager.register(event: .sdkUpdated, task: updatedTask)
        eventManager.start()

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)

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
        wait(for: [expectation, sdkUpdatedExp], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready should be triggered");
        XCTAssertTrue(updatedTask.taskTriggered, "SDK Update should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out shouldn't be triggered");
    }

    func testSplitKilledWhenReady() {
        let sdkUpdatedExp = XCTestExpectation()

        let client =  SplitClientStub()
        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.executorResources.client = client
        let updatedTask = sdkTask(exp: sdkUpdatedExp)
        eventManager.register(event: .sdkUpdated, task: updatedTask)
        eventManager.start()

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitKilledNotification)

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
        wait(for: [expectation, sdkUpdatedExp], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady), "SDK Ready should be triggered");
        XCTAssertTrue(updatedTask.taskTriggered, "SDK Update should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut), "SDK Time out shouldn't be triggered");
    }

    func testSplitKilledNoSdkReady() {
        let sdkTiemoutExp = XCTestExpectation()
        let timeout = 3.0
        let client =  SplitClientStub()
        let config: SplitClientConfig = SplitClientConfig()
        config.sdkReadyTimeOut = Int(timeout) - 1
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.executorResources.client = client
        let timeOutTask = sdkTask(exp: sdkTiemoutExp)
        let updatedTask = sdkTask(exp: sdkTiemoutExp)
        eventManager.register(event: .sdkUpdated, task: updatedTask)
        eventManager.register(event: .sdkReadyTimedOut, task: timeOutTask)
        eventManager.start()

        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsUpdated)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitKilledNotification)

        wait(for: [sdkTiemoutExp], timeout: timeout)

        XCTAssertFalse(updatedTask.taskTriggered);
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReady));
        XCTAssertTrue(timeOutTask.taskTriggered);
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyTimedOut));
    }
    
    // MARK: Helpers
    func currentTimestamp() -> Int {
        return Int(Date().unixTimestamp())
    }

    func sdkTask(exp: XCTestExpectation) -> TestTask {
        return TestTask(exp: exp)
    }
}

class TestTask: SplitEventTask {
    var taskTriggered = false
    var exp: XCTestExpectation?
    init(exp: XCTestExpectation?) {
        self.exp = exp
    }
    override func onPostExecute(client: SplitClient) {
    }

    override func onPostExecuteView(client: SplitClient) {
        taskTriggered = true
        if let exp = self.exp {
            exp.fulfill()
        }
    }
}
