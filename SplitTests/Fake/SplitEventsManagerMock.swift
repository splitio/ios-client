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
    
    var isSdkReadyFired: Bool {
        return isSegmentsReadyFired && isSplitsReadyFired
    }
    var isSegmentsReadyFired = false
    var isSplitsReadyFired = false
    var isSdkTimeoutFired = false
    
    func notifyInternalEvent(_ event:SplitInternalEvent) {
        switch event {
        case .mySegmentsAreReady:
            isSegmentsReadyFired = true
        case .splitsAreReady:
            isSplitsReadyFired = true
        case .sdkReadyTimeoutReached:
            isSdkTimeoutFired = true
        default:
            print("\(event)")
        }
    }
    
    func getExecutorResources() -> SplitEventExecutorResources {
        return SplitEventExecutorResources()
    }
    
    func register(event: SplitEvent, task: SplitEventTask) {
    }
    
    func start() {
    }
    
    func eventAlreadyTriggered(event: SplitEvent) -> Bool {
        return true
    }
    
    func getExecutionTimes() -> [String: Int] {
        return [String:Int]()
    }
}
