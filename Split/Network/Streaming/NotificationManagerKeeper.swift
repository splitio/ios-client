//
//  NotificationManagerKeeper.swift
//  Split
//
//  Created by Javier L. Avrudsky on 01/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol NotificationManagerKeeper {
    var publishersCount: Int { get }
    func handleIncomingPresenceEvent(notification: OccupancyNotification)
}

class DefaultNotificationManagerKeeper: NotificationManagerKeeper {

    var publishersCount: Int {
        return priPublishers + secPublishers
    }

    /// By default we consider one publisher en primary channel available
    private var priPublishers = 1
    private var secPublishers = 0

    private var broadcasterChannel: PushManagerEventBroadcaster

    init(broadcasterChannel: PushManagerEventBroadcaster) {
        self.broadcasterChannel = broadcasterChannel
    }

    func handleIncomingPresenceEvent(notification: OccupancyNotification) {
        let prevPriPublishers = priPublishers
        let prevSecPublishers = secPublishers
        if notification.isControlPriChannel {
            priPublishers = notification.metrics.publishers
        } else if notification.isControlSecChannel {
            secPublishers = notification.metrics.publishers
        } else {
            return
        }

        if priPublishers + secPublishers == 0 && prevPriPublishers + prevSecPublishers > 0 {
            broadcasterChannel.push(event: .pushSubsystemDown)
            return
        }

        if priPublishers + secPublishers > 0 && prevPriPublishers + prevSecPublishers == 0 {
            broadcasterChannel.push(event: .pushSubsystemUp)
            return
        }
    }
}
