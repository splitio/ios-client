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

    let executorResources: SplitEventExecutorResources = SplitEventExecutorResources()
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
    
    func notifyInternalEvent(_ event:SplitInternalEvent) {
        switch event {
        case .mySegmentsUpdated:
            isSegmentsReadyFired = true
        case .splitsUpdated:
            isSplitsReadyFired = true
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
    }
    
    func start() {
    }

    func stop() {
    }
    
    func eventAlreadyTriggered(event: SplitEvent) -> Bool {
        switch event {
        case.sdkReady:
            return isSdkReadyFired
        case.sdkReadyFromCache:
            return isSdkReadyFromCacheFired
        case .sdkReadyTimedOut:
            return isSdkTimeoutFired

        default:
            return true
        }
    }
}
