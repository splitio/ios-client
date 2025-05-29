//
//  PushManagerEventBroadcaster.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 26/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

enum SyncStatusEvent: Equatable {
    case pushSubsystemUp
    case pushSubsystemDown
    case pushRetryableError
    case pushNonRetryableError
    case pushSubsystemDisabled
    case pushReset
    case pushDelayReceived(delaySeconds: Int64)
    case syncExecuted
    case uriTooLongOnSync
    case splitLoadedFromCache
}

protocol SyncEventBroadcaster {
    typealias IncomingMessageHandler = (SyncStatusEvent) -> Void
    func push(event: SyncStatusEvent)
    func register(handler: @escaping IncomingMessageHandler)
    func destroy()
}

///
/// Component to allow push notification manager to comunicate status events
/// to other components
///
class DefaultSyncEventBroadcaster: SyncEventBroadcaster {
    let messageQueue = DispatchQueue(
        label: "split-sync-event-broadcaster",
        attributes: .concurrent)
    var handlers = [IncomingMessageHandler]()
    var id = UUID().uuidString

    func push(event: SyncStatusEvent) {
        messageQueue.async { [weak self] in
            guard let self = self else { return }
            for handler in self.handlers {
                handler(event)
            }
        }
    }

    func register(handler: @escaping IncomingMessageHandler) {
        messageQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.handlers.append(handler)
        }
    }

    func destroy() {
        messageQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.handlers.removeAll()
        }
    }
}
