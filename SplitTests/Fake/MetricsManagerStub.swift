//
//  MetricsManagerStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 05/07/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

class MetricsManagerStub: MetricsManager {
    var timeCalled = false
    var countCalled = false
    func time(microseconds latency: Int64, for operationName: String) {
        timeCalled = true
    }
    
    func count(delta: Int64, for counterName: String) {
        countCalled = true
    }
    
    func flush() {
    }
}
