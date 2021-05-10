//
//  SplitEventsManagerMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 24/04/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitEventsManagerMock: SplitEventsManager {

    let executorResources: SplitEventExecutorResources = SplitEventExecutorResources()
    var isSdkReadyFired: Bool {
        return isSegmentsReadyFired && isSplitsReadyFired
    }
    var isSegmentsReadyFired = false
    var isSplitsReadyFired = false
    var isSdkTimeoutFired = false
    
    func notifyInternalEvent(_ event:SplitInternalEvent) {
        switch event {
        case .mySegmentsUpdated:
            isSegmentsReadyFired = true
        case .splitsUpdated:
            isSplitsReadyFired = true
        case .sdkReadyTimeoutReached:
            isSdkTimeoutFired = true
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
        if event == .sdkReady {
            return isSdkReadyFired
        }
        return true
    }
}
