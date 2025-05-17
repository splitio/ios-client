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
    var isSdkErrorFired = false
    var isSplitUpdatedTriggered = false
    var isSdkUpdatedFired = false
    var isSdkReadyChecked = false
    
    var metadata: SplitMetadata?

    // MARK: Notifiers
    func notifyInternalEvent(_ event: SplitInternalEvent) {
        switch event {
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
    
    func notifyInternalEvent(_ event: SplitInternalEvent, metadata: SplitMetadata?) {
        self.metadata = metadata
        notifyInternalEvent(event)
    }
    
    // MARK: Registers
    var registeredEvents = [SplitEvent: SplitEventActionTask]()
    func register(event: SplitEvent, task: SplitEventActionTask) {
        register(event: SplitEventWithMetadata(type: event), task: task)
    }
    
    func register(event: SplitEventWithMetadata, task: SplitEventActionTask) {
        registeredEvents[event.type] = task
    }
    
    func start() {}

    func stop() {}
    
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
        case .sdkError:
            return isSdkErrorFired

        default:
            return true
        }
    }
}
