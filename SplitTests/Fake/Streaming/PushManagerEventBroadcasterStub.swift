//
//  EventBroadcasterChannelStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 02/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class PushManagerEventBroadcasterStub: PushManagerEventBroadcaster {

    var pushedEvent: PushStatusEvent?

    func push(event: PushStatusEvent) {
        pushedEvent = event
    }

    func register(handler: @escaping IncomingMessageHandler) {
    }

    func stop() {
    }
}
