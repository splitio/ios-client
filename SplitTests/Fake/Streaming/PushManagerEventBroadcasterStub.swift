//
//  EventBroadcasterChannelStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 02/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class PushManagerEventBroadcasterStub: PushManagerEventBroadcaster {
    var registeredHandler: IncomingMessageHandler?
    private var pushExpectationCallCount = 0
    var pushExpectationTriggerCallCount = 1
    var pushExpectation: XCTestExpectation?
    var lastPushedEvent: PushStatusEvent?
    var pushedEvents = [PushStatusEvent]()

    func push(event: PushStatusEvent) {
        lastPushedEvent = event
        pushedEvents.append(event)
        pushExpectationCallCount+=1
        if let handler = registeredHandler {
            handler(event)
        }
        if pushExpectationCallCount == pushExpectationTriggerCallCount, let exp = pushExpectation {
            exp.fulfill()
        }
    }

    func register(handler: @escaping IncomingMessageHandler) {
        registeredHandler = handler
    }

    func destroy() {
    }
}
