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
    let messageQueue = DispatchQueue(label: "pushMananagerMessagerQueue",
                                     attributes: .concurrent)
    var handlers = [IncomingMessageHandler]()

    func push(event: PushStatusEvent) {
        messageQueue.async {
            for handler in self.handlers {
                handler(event)
            }
        }
    }

    func register(handler: @escaping IncomingMessageHandler) {
        messageQueue.async (flags: .barrier) {
            self.handlers.append(handler)
        }
    }

    func stop() {
        messageQueue.async (flags: .barrier) {
            self.handlers.removeAll()
        }
    }
}
