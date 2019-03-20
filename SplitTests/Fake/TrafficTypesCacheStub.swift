//
//  TrafficTypesCacheStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 20/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split
class TrafficTypesCacheStub: TrafficTypesCache {
    var updateCallCount: Int = 0
    var containsCallCount: Int = 0
    
    func update(from: [Split]) {
        updateCallCount += 1
    }
    
    func contains(name: String) -> Bool {
        containsCallCount += 1
        return true
    }
    
    func updateWasCalled() -> Bool {
        return updateCallCount > 0
    }
    
    func containsWasCalled() -> Bool {
        return containsCallCount > 0
    }
    
}
