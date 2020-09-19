//
//  TrackManagerStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class TrackManagerStub: TrackManager {
    var startCalled = false
    var stopCalled = false
    var flushCalled = false
    var appendEventCalled = false

    func start() {
        startCalled = true
    }

    func stop() {
        stopCalled = true
    }

    func flush() {
        flushCalled = true
    }

    func appendEvent(event: EventDTO) {
        appendEventCalled = true
    }


}
