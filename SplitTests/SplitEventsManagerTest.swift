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
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func testSdkReadyEvent() {
    
        let config: SplitClientConfig = SplitClientConfig()
        config.sdkReadyTimeOut = 100
        
        let eventManager:SplitEventsManager = SplitEventsManager(config: config)
        eventManager.start()
        
        eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsAreReady)
        eventManager.notifyInternalEvent(SplitInternalEvent.splitsAreReady)
        eventManager.notifyInternalEvent(SplitInternalEvent.sdkReadyTimeoutReached)

        sleep(2)
        assert(eventManager.getExecutionTimes()[SplitEvent.sdkReady.toString()]! > 0)
    }
}
