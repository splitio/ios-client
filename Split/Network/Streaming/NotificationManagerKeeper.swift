//
//  NotificationManagerKeeper.swift
//  Split
//
//  Created by Javier L. Avrudsky on 01/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol NotificationManagerKeeper {
    var isStreamingActive: Bool { get }
    func handleIncomingPresenceEvent(notification: OccupancyNotification)
    func handleIncomingControl(notification: ControlNotification)
}

class DefaultNotificationManagerKeeper: NotificationManagerKeeper {

    struct PublishersInfo {
        var count: Int
        var lastTimestamp: Int64
    }

    let kChannelPriIndex = 0
    let kChannelSecIndex = 1

    /// By default we consider one publisher en primary channel available
    private var publishersInfo = [
        PublishersInfo(count: 1, lastTimestamp: 0),
        PublishersInfo(count: 0, lastTimestamp: 0)
    ]

    private var publishersCount: Int {
        var count = 0
        DispatchQueue.global().sync {
            count = publishersInfo[kChannelPriIndex].count + publishersInfo[kChannelSecIndex].count
        }
        return count
    }

    private let broadcasterChannel: PushManagerEventBroadcaster
    private let telemetryProducer: TelemetryRuntimeProducer?

    private var streamingActive = true
    var isStreamingActive: Bool {
        var active = false
        DispatchQueue.global().sync {
            active = streamingActive
        }
        return active
    }

    init(broadcasterChannel: PushManagerEventBroadcaster,
         telemetryProducer: TelemetryRuntimeProducer?) {
        self.broadcasterChannel = broadcasterChannel
        self.telemetryProducer = telemetryProducer
    }

    func handleIncomingControl(notification: ControlNotification) {
        switch notification.controlType {
        case .streamingPaused:
            updateStreamingState(active: false)
            broadcasterChannel.push(event: .pushSubsystemDown)
            self.telemetryProducer?.recordStreamingEvent(type: .streamingStatus,
                                                         data: TelemetryStreamingEventValue.streamingPaused)

        case .streamingDisabled:
            updateStreamingState(active: false)
            broadcasterChannel.push(event: .pushSubsystemDisabled)
            self.telemetryProducer?.recordStreamingEvent(type: .streamingStatus,
                                                         data: TelemetryStreamingEventValue.streamingDisabled)

        case .streamingEnabled:
            updateStreamingState(active: true)
            if publishersCount > 0 {
                broadcasterChannel.push(event: .pushSubsystemUp)
                self.telemetryProducer?.recordStreamingEvent(type: .streamingStatus,
                                                             data: TelemetryStreamingEventValue.streamingEnabled)
            }

        case .streamingReset:
            broadcasterChannel.push(event: .pushReset)

        case .unknown:
            Logger.w("Unknown control notification received")
        }
    }

    func handleIncomingPresenceEvent(notification: OccupancyNotification) {
        let channelIndex = getChannelIndex(of: notification)

        if channelIndex == -1 || isOldTimestamp(notification: notification, for: channelIndex) {
            return
        }
        update(timestamp: notification.timestamp, for: channelIndex)
        let prevPublishersCount = publishersCount
        update(count: notification.metrics.publishers, for: channelIndex)

        let eventType = channelIndex == kChannelPriIndex
            ? TelemetryStreamingEventType.occupancyPri
            : TelemetryStreamingEventType.occupancySec
        telemetryProducer?.recordStreamingEvent(type: eventType, data: Int64(notification.metrics.publishers))

        if publishersCount == 0 && prevPublishersCount > 0 {
            broadcasterChannel.push(event: .pushSubsystemDown)
            return
        }

        if publishersCount > 0 && prevPublishersCount == 0 && isStreamingActive {
            broadcasterChannel.push(event: .pushSubsystemUp)
            return
        }
    }

    private func isOldTimestamp(notification: OccupancyNotification, for channelIndex: Int) -> Bool {
        var timestamp: Int64 = 0
        DispatchQueue.global().sync {
            timestamp =  publishersInfo[channelIndex].lastTimestamp
        }
        return timestamp >= notification.timestamp
    }

    private func update(count: Int, for channelIndex: Int) {
        DispatchQueue.global().sync {
            publishersInfo[channelIndex].count = count
        }
    }

    private func update(timestamp: Int64, for channelIndex: Int) {
        DispatchQueue.global().sync {
            publishersInfo[channelIndex].lastTimestamp = timestamp
        }
    }

    private func publishers(in channelIndex: Int) -> Int {
        var count = 0
        DispatchQueue.global().sync {
            count =  publishersInfo[channelIndex].count
        }
        return count
    }

    private func getChannelIndex(of notification: OccupancyNotification) -> Int {
        if notification.isControlPriChannel {
            return kChannelPriIndex
        } else if notification.isControlSecChannel {
            return kChannelSecIndex
        } else {
            Logger.w("Unknown occupancy channel \(notification.channel ?? "null")")
            return -1
        }
    }

    private func updateStreamingState(active: Bool) {
        DispatchQueue.global().sync {
            Logger.d("Streaming active = \(active)")
            streamingActive = active
        }
    }

}
