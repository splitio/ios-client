//
//  SplitEventsManagerTest.swift
//  Split_Tests
//
//  Created by Sebastian Arrubia on 4/24/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Split

class SplitEventsManagerTest: QuickSpec {
    
    override func spec() {
        
        describe("SplitEventsManagerTest") {
            let config: SplitClientConfig = SplitClientConfig()
            config.readyTimeOut(100)
            
            let eventManager:SplitEventsManager = SplitEventsManager(config: config)
            eventManager.start()
            
            eventManager.notifyInternalEvent(SplitInternalEvent.mySegmentsAreReady)
            eventManager.notifyInternalEvent(SplitInternalEvent.splitsAreReady)
            eventManager.notifyInternalEvent(SplitInternalEvent.sdkReadyTimeoutReached)
            
            DispatchQueue(label:"testing.queue").sync(execute: {
                sleep(2)
            })
            assert(eventManager.getExecutionTimes()[SplitEvent.sdkReady.toString()]! > 0)
            //assert(eventManager.getExecutionTimes()[SplitEvent.sdkReadyTimedOut.toString()] == 0)
        }
        
    }
    
    

}
