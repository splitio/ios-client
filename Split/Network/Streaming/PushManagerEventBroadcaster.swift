//
//  PushManagerEventBroadcaster.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 26/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

enum PushStatusEvent {
    case disablePolling
    case enablePolling
}

protocol PushManagerEventBroadcaster {
    typealias IncomingMessageHandler = (PushStatusEvent) -> Void
    func push(event: PushStatusEvent)
    func register(handler: @escaping IncomingMessageHandler)
    func stop()
}

///
/// Component to allow push notification manager to comunicate status events
/// to other components
///
class DefaultPushManagerEventBroadcaster: PushManagerEventBroadcaster {
    var handlers = [IncomingMessageHandler]()

    func push(event: PushStatusEvent) {
        for handler in handlers {
            handler(event)
        }
    }

    func register(handler: @escaping IncomingMessageHandler) {
        handlers.append(handler)
    }

    func stop() {
        handlers.removeAll()
    }
}
