//
//  SplitEventsManagerMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 24/04/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class SplitEventsManagerMock: SplitEventsManager {

    var timeoutExp: XCTestExpectation?
    var readyExp: XCTestExpectation?

    var isSdkReadyFired: Bool {
        return isSegmentsReadyFired && isSplitsReadyFired
    }
    var isSdkReadyFromCacheFired: Bool {
        return isSegmentsReadyFromCacheFired && isSplitsReadyFromCacheFired
    }
    var isSegmentsReadyFired = false
    var isSplitsReadyFired = false
    var isSegmentsReadyFromCacheFired = false
    var isSplitsReadyFromCacheFired = false
    var isSdkTimeoutFired = false

    var isSplitUpdatedTriggered = false
    var isSdkUpdatedFired = false

    var isSdkReadyChecked = false

    func notifyInternalEvent(_ event: SplitInternalEvent) {
        notifyInternalEvent(SplitInternalEventWithMetadata(event, metadata: nil))
    }
    
    func notifyInternalEvent(_ event: SplitInternalEventWithMetadata) {
        switch event.type {
            case .mySegmentsUpdated:
                isSegmentsReadyFired = true
            case .splitsUpdated:
                isSplitsReadyFired = true
                isSplitUpdatedTriggered = true
                if let exp = readyExp {
                    exp.fulfill()
                }
            case .sdkReadyTimeoutReached:
                isSdkTimeoutFired = true
                if let exp = timeoutExp {
                    exp.fulfill()
                }
            default:
                print("\(event)")
        }
    }

    func register(event: SplitEvent, task: SplitEventTask) {
        register(event: SplitEventWithMetadata(event, metadata: nil), task: task)
    }

    var registeredEvents = [SplitEventWithMetadata: SplitEventTask]()
    func register(event: SplitEventWithMetadata, task: SplitEventTask) {
        registeredEvents[event] = task
    }
    
    func start() {
    }

    func stop() {
    }
    
    func eventAlreadyTriggered(event: SplitEvent) -> Bool {
        switch event {
        case.sdkReady:
            isSdkReadyChecked = true
            return isSdkReadyFired
        case.sdkReadyFromCache:
            return isSdkReadyFromCacheFired
        case .sdkReadyTimedOut:
            return isSdkTimeoutFired
        case .sdkUpdated:
            return isSdkUpdatedFired

        default:
            return true
        }
    }
}
