//
//  EventsTrackerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 02-Dec-2022.
//  Copyright © 2022 Split. All rights reserved.
//

@testable import Split
import XCTest

class EventsTrackerStub: EventsTracker {
    var isTrackingEnabled: Bool = true

    var trackCalled = false
    var trackResponse = true
    func track(
        eventType: String,
        trafficType: String?,
        value: Double?,
        properties: [String: Any]?,
        matchingKey: String,
        isSdkReady: Bool) -> Bool {
        return trackResponse
    }
}
