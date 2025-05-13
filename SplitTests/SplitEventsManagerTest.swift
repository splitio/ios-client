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
    
    let expectationTimeOut = 10.0
    let intervalExecutionTime = 1
    var queue = DispatchQueue(label: "test", attributes: .concurrent)
    
    func testSdkReady() {
        var shouldStop = false
        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        let updatedTask = TestTask(exp: nil)
        eventManager.register(event: SplitEvent(type: .sdkUpdated), task: updatedTask)
        eventManager.start()
        
        eventManager.notifyInternalEvent(.mySegmentsUpdated)
        eventManager.notifyInternalEvent(.myLargeSegmentsUpdated)
        eventManager.notifyInternalEvent(.splitsUpdated)
        eventManager.notifyInternalEvent(.splitsUpdated)
        ThreadUtils.delay(seconds: 0.2)
        
        let expectation = XCTestExpectation(description: "SDK Readky triggered")
        queue.async {
            while !shouldStop {
                sleep(UInt32(self.intervalExecutionTime))
                if eventManager.eventAlreadyTriggered(event: .sdkReady) {
                    shouldStop = true;
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: expectationTimeOut)
        
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: .sdkReady), "SDK Ready should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: .sdkUpdated), "SDK Update shouldn't be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: .sdkReadyTimedOut), "SDK Time out shouldn't be triggered");

        eventManager.stop()
    }

    func testSdkReadyFromCacheAndReady() {

        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.start()

        eventManager.notifyInternalEvent(.mySegmentsLoadedFromCache)
        eventManager.notifyInternalEvent(.myLargeSegmentsLoadedFromCache)
        eventManager.notifyInternalEvent(.splitsLoadedFromCache)
        eventManager.notifyInternalEvent(.attributesLoadedFromCache)

        eventManager.notifyInternalEvent(.mySegmentsUpdated)
        eventManager.notifyInternalEvent(.myLargeSegmentsUpdated)
        eventManager.notifyInternalEvent(.splitsUpdated)
        var shouldStop = false
        let expectation = XCTestExpectation(description: "SDK Readky from cache triggered")
        queue.async {
            while !shouldStop {
                sleep(UInt32(self.intervalExecutionTime))
                if eventManager.eventAlreadyTriggered(event: .sdkReady) {
                    shouldStop = true;
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: .sdkReadyFromCache), "SDK Ready should from cache be triggered");
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: .sdkReady), "SDK Ready should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: .sdkReadyTimedOut), "SDK Time out shouldn't be triggered");

        eventManager.stop()
    }

    func testSdkReadyFromCacheAndReadyTimeout() {

        let config: SplitClientConfig = SplitClientConfig()
        config.sdkReadyTimeOut = 1000
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.start()

        let cacheExp = XCTestExpectation()
        eventManager.register(event: SplitEvent(type: .sdkReadyFromCache), task: TestTask(exp: cacheExp))
        let timeoutExp = XCTestExpectation()
        eventManager.register(event: SplitEvent(type: .sdkReadyTimedOut), task: TestTask(exp: timeoutExp))

        eventManager.notifyInternalEvent(.mySegmentsLoadedFromCache)
        eventManager.notifyInternalEvent(.myLargeSegmentsLoadedFromCache)
        eventManager.notifyInternalEvent(.splitsLoadedFromCache)
        eventManager.notifyInternalEvent(.attributesLoadedFromCache)
        eventManager.notifyInternalEvent(.sdkReadyTimeoutReached)

        wait(for: [cacheExp, timeoutExp], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: .sdkReadyFromCache), "SDK Ready should from cache be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: .sdkReady), "SDK Ready should not be triggered");
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: .sdkReadyTimedOut), "SDK Time out should be triggered");

        eventManager.stop()
    }
    
    func testSdkReadyTimeOut() {
        
        let config: SplitClientConfig = SplitClientConfig()
        config.sdkReadyTimeOut = 1000
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.start()

        let timeoutExp = XCTestExpectation()
        eventManager.register(event: SplitEvent(type: .sdkReadyTimedOut), task: TestTask(exp: timeoutExp))
        wait(for: [timeoutExp], timeout: expectationTimeOut)
        
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: .sdkReadyTimedOut), "SDK Time out should be triggered")
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: .sdkReady), "SDK Ready shouldn't be triggered")

        eventManager.stop()
    }
    
    func testSdkReadyAndReadyTimeOut() {
        
        let config: SplitClientConfig = SplitClientConfig()
        config.sdkReadyTimeOut = 1000
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.start()

        let expectationTimeout = XCTestExpectation(description: "SDK Readky triggered")
        eventManager.register(event: SplitEvent(type: .sdkReadyTimedOut), task: TestTask(exp: expectationTimeout))

        wait(for: [expectationTimeout], timeout: expectationTimeOut)
        
        //At this line timeout has been reached
        let timeoutTriggered  = eventManager.eventAlreadyTriggered(event: .sdkReadyTimedOut)

        let readyExp = XCTestExpectation(description: "SDK Readky triggered")
        eventManager.register(event: SplitEvent(type: .sdkReady), task: TestTask(exp: readyExp))

        eventManager.notifyInternalEvent(.mySegmentsUpdated)
        eventManager.notifyInternalEvent(.myLargeSegmentsUpdated)
        eventManager.notifyInternalEvent(.splitsUpdated)

        wait(for: [readyExp], timeout: expectationTimeOut)
        
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: .sdkReady), "SDK Ready should be triggered");
        XCTAssertTrue(timeoutTriggered)

        eventManager.stop()
    }

    func testSdkUpdateSplits() {
        let sdkUpdatedExp = XCTestExpectation()

        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.start()

        let readyExp = XCTestExpectation()
        let updatedTask = sdkTask(exp: sdkUpdatedExp)
        eventManager.register(event: SplitEvent(type: .sdkReady), task: TestTask(exp: readyExp))
        eventManager.register(event: SplitEvent(type: .sdkUpdated), task: updatedTask)

        eventManager.notifyInternalEvent(.mySegmentsUpdated)
        eventManager.notifyInternalEvent(.myLargeSegmentsUpdated)
        eventManager.notifyInternalEvent(.splitsUpdated)
        ThreadUtils.delay(seconds: 0.5)
        eventManager.notifyInternalEvent(.splitsUpdated)

        wait(for: [readyExp, sdkUpdatedExp], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: .sdkReady), "SDK Ready should be triggered");
        XCTAssertTrue(updatedTask.taskTriggered, "SDK Update should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: .sdkReadyTimedOut), "SDK Time out shouldn't be triggered");

        eventManager.stop()
    }

    func testSdkUpdateMySegments() {
        let sdkUpdatedExp = XCTestExpectation()

        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.start()
        let readyExp = XCTestExpectation()
        let updatedTask = sdkTask(exp: sdkUpdatedExp)
        eventManager.register(event: SplitEvent(type: .sdkReady), task: TestTask(exp: readyExp))
        eventManager.register(event: SplitEvent(type: .sdkUpdated), task: updatedTask)


        eventManager.notifyInternalEvent(.splitsUpdated)
        eventManager.notifyInternalEvent(.mySegmentsUpdated)
        eventManager.notifyInternalEvent(.myLargeSegmentsUpdated)
        ThreadUtils.delay(seconds: 0.5)
        eventManager.notifyInternalEvent(.mySegmentsUpdated)

        wait(for: [readyExp, sdkUpdatedExp], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: .sdkReady), "SDK Ready should be triggered");
        XCTAssertTrue(updatedTask.taskTriggered, "SDK Update should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: .sdkReadyTimedOut), "SDK Time out shouldn't be triggered");

        eventManager.stop()
    }

    func testSplitKilledWhenReady() {

        let config: SplitClientConfig = SplitClientConfig()
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        eventManager.start()
        let readyExp = XCTestExpectation()
        let sdkUpdatedExp = XCTestExpectation()
        let updatedTask = sdkTask(exp: sdkUpdatedExp)
        eventManager.register(event: SplitEvent(type: .sdkReady), task: TestTask(exp: readyExp))
        eventManager.register(event: SplitEvent(type: .sdkUpdated), task: updatedTask)

        eventManager.notifyInternalEvent(.mySegmentsUpdated)
        eventManager.notifyInternalEvent(.myLargeSegmentsUpdated)
        eventManager.notifyInternalEvent(.splitsUpdated)
        ThreadUtils.delay(seconds: 0.5)
        eventManager.notifyInternalEvent(.splitKilledNotification)

        wait(for: [readyExp, sdkUpdatedExp], timeout: expectationTimeOut)

        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: .sdkReady), "SDK Ready should be triggered");
        XCTAssertTrue(updatedTask.taskTriggered, "SDK Update should be triggered");
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: .sdkReadyTimedOut), "SDK Time out shouldn't be triggered");

        eventManager.stop()
    }

    func testSplitKilledNoSdkReady() {
        let sdkTiemoutExp = XCTestExpectation()
        let timeout = 3.0
        let config: SplitClientConfig = SplitClientConfig()
        config.sdkReadyTimeOut = Int(timeout) - 1
        let eventManager: SplitEventsManager = DefaultSplitEventsManager(config: config)
        let timeOutTask = sdkTask(exp: sdkTiemoutExp)
        let updatedTask = sdkTask(exp: sdkTiemoutExp)
        eventManager.register(event: SplitEvent(type: .sdkUpdated), task: updatedTask)
        eventManager.register(event: SplitEvent(type: .sdkReadyTimedOut), task: timeOutTask)
        eventManager.start()

        eventManager.notifyInternalEvent(SplitInternalEvent(.mySegmentsUpdated))
        eventManager.notifyInternalEvent(SplitInternalEvent(.splitKilledNotification))

        wait(for: [sdkTiemoutExp], timeout: timeout)

        XCTAssertFalse(updatedTask.taskTriggered);
        XCTAssertFalse(eventManager.eventAlreadyTriggered(event: .sdkReady));
        XCTAssertTrue(timeOutTask.taskTriggered);
        XCTAssertTrue(eventManager.eventAlreadyTriggered(event: .sdkReadyTimedOut));

        eventManager.stop()
    }
    
    // MARK: Helpers
    func currentTimestamp() -> Int {
        return Int(Date().unixTimestamp())
    }

    func sdkTask(exp: XCTestExpectation) -> TestTask {
        return TestTask(exp: exp)
    }
}

class TestTask: SplitEventActionTask {
    var taskTriggered = false
    let label: String
    var exp: XCTestExpectation?
    var metadata: SplitMetadata?
    
    init(exp: XCTestExpectation?, label: String = "") {
        self.exp = exp
        self.label = label
        super.init(action: {}, event: .sdkReady, runInBackground: false, factory: SplitFactoryStub(apiKey: IntegrationHelper.dummyApiKey))
    }

    override func run(_ metadata : SplitMetadata?) {
        print("run: \(self.label)")
        taskTriggered = true
        if let exp = self.exp {
            exp.fulfill()
        }
    }
}
