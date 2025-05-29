//
//  NotificationManagerKeeperTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 02/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class NotificationManagerKeeperTest: XCTestCase {
    private let kControlPriChannel = "[?occupancy=metrics.publishers]control_pri"
    private let kControlSecChannel = "[?occupancy=metrics.publishers]control_sec"

    var broadcasterChannel: SyncEventBroadcasterStub!
    var notificationManager: NotificationManagerKeeper!
    var telemetryProducer: TelemetryStorageStub!

    override func setUp() {
        telemetryProducer = TelemetryStorageStub()
        broadcasterChannel = SyncEventBroadcasterStub()
        notificationManager = DefaultNotificationManagerKeeper(
            broadcasterChannel: broadcasterChannel,
            telemetryProducer: telemetryProducer)
    }

    func testNoAvailablePublishers() {
        // Notification manager keeper start assuming one publisher in primary channel
        // Receiving 0 publishers in primary and having 0 in sec, should enable polling
        var notification = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 0))
        notification.channel = kControlPriChannel
        notification.timestamp = 100
        notificationManager.handleIncomingPresenceEvent(notification: notification)

        let streamEvents = telemetryProducer.streamingEvents

        XCTAssertEqual(SyncStatusEvent.pushSubsystemDown, broadcasterChannel.lastPushedEvent)

        XCTAssertNotNil(streamEvents[.occupancyPri])
    }

    func testNoAvailablePublishersOldTimestamp() {
        // Notification manager keeper start assuming one publisher in primary channel
        // Receiving 0 (old timestamp) should not enable polling
        var notification = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 0))
        notification.channel = kControlPriChannel
        notification.timestamp = 0
        notificationManager.handleIncomingPresenceEvent(notification: notification)

        let streamEvents = telemetryProducer.streamingEvents

        XCTAssertNil(broadcasterChannel.lastPushedEvent)
        XCTAssertNil(streamEvents[.occupancyPri])
    }

    func testNoAvailablePublishersInPriButAvailableInSec() {
        // Notification manager keeper start assuming one publisher in primary channel
        // Here we disable enable secondary channel (publishers = 1 notification) then
        // Primary is enabled (publishers = 0).
        // No event should be sent through broadcaster channel

        // making channel sec available
        var n1 = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 1))
        n1.channel = kControlSecChannel
        notificationManager.handleIncomingPresenceEvent(notification: n1)

        // reseting stub
        broadcasterChannel.lastPushedEvent = nil

        // now no publishers in primary channel shouldn't enable polling
        var n2 = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 0))
        n2.channel = kControlPriChannel
        notificationManager.handleIncomingPresenceEvent(notification: n2)

        let streamEvents = telemetryProducer.streamingEvents

        XCTAssertNil(broadcasterChannel.lastPushedEvent)
        XCTAssertNil(streamEvents[.occupancyPri])
        XCTAssertNil(streamEvents[.occupancySec])
    }

    func testSecondaryAvailableNotificationReceivedWhenNoPublishers() {
        // Notification manager keeper start assuming one publisher in primary channel
        // Receiving 0 publishers in primary and having 0 in sec to enable polling
        // Receiving 1 publisher in secondary channel must enable polling

        // making channel pri unavailable
        var n1 = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 0))
        n1.channel = kControlPriChannel
        n1.timestamp = 50
        notificationManager.handleIncomingPresenceEvent(notification: n1)

        // reseting stub
        broadcasterChannel.lastPushedEvent = nil

        // now publishers in secondary channel must disable polling
        var n2 = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 1))
        n2.channel = kControlSecChannel
        n2.timestamp = 100
        notificationManager.handleIncomingPresenceEvent(notification: n2)

        XCTAssertEqual(SyncStatusEvent.pushSubsystemUp, broadcasterChannel.lastPushedEvent)
    }

    func testSecondaryAvailableNotificationReceivedWhenNoPublishersOldTimestamp() {
        // Notification manager keeper start assuming one publisher in primary channel
        // Receiving 0 publishers in primary and having 0 in sec to enable polling
        // Receiving 1 publisher in secondary channel must enable polling

        // making channel pri unavailable
        var n1 = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 0))
        n1.channel = kControlPriChannel
        n1.timestamp = 50
        notificationManager.handleIncomingPresenceEvent(notification: n1)

        // now publishers in secondary channel = 0 to set last timestamp for channel sec
        var n2 = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 0))
        n2.channel = kControlSecChannel
        n2.timestamp = 50
        notificationManager.handleIncomingPresenceEvent(notification: n2)

        // reseting stub
        broadcasterChannel.lastPushedEvent = nil

        // old timestamp notification should not fire any event
        var n3 = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 1))
        n3.channel = kControlSecChannel
        n3.timestamp = 30
        notificationManager.handleIncomingPresenceEvent(notification: n3)

        XCTAssertNil(broadcasterChannel.lastPushedEvent)
    }

    func testIncomingControlStreamingEnabled() {
        // making channel pri unavailable
        var n1 = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 1))
        n1.channel = kControlPriChannel
        n1.timestamp = 50
        notificationManager.handleIncomingPresenceEvent(notification: n1)

        // reseting pushed event
        broadcasterChannel.lastPushedEvent = nil
        let controlNotification = ControlNotification(type: .control, controlType: .streamingResumed)
        notificationManager.handleIncomingControl(notification: controlNotification)

        XCTAssertEqual(SyncStatusEvent.pushSubsystemUp, broadcasterChannel.lastPushedEvent)
    }

    func testIncomingControlStreamingPaused() {
        // making channel pri unavailable
        var n1 = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 1))
        n1.channel = kControlPriChannel
        n1.timestamp = 50
        notificationManager.handleIncomingPresenceEvent(notification: n1)

        // reseting pushed event
        broadcasterChannel.lastPushedEvent = nil
        let controlNotification = ControlNotification(type: .control, controlType: .streamingPaused)
        notificationManager.handleIncomingControl(notification: controlNotification)

        XCTAssertEqual(SyncStatusEvent.pushSubsystemDown, broadcasterChannel.lastPushedEvent)
    }

    func testIncomingControlStreamingReset() {
        // making channel pri available
        var n1 = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 1))
        n1.channel = kControlPriChannel
        n1.timestamp = 50
        notificationManager.handleIncomingPresenceEvent(notification: n1)

        // reseting pushed event
        broadcasterChannel.lastPushedEvent = nil
        let controlNotification = ControlNotification(type: .control, controlType: .streamingReset)
        notificationManager.handleIncomingControl(notification: controlNotification)

        XCTAssertEqual(SyncStatusEvent.pushReset, broadcasterChannel.lastPushedEvent)
    }

    func testIncomingControlStreamingEnabledNoPublishers() {
        // making channel pri unavailable
        var n1 = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 0))
        n1.channel = kControlPriChannel
        n1.timestamp = 50
        notificationManager.handleIncomingPresenceEvent(notification: n1)

        // reseting pushed event
        broadcasterChannel.lastPushedEvent = nil
        let controlNotification = ControlNotification(type: .control, controlType: .streamingResumed)
        notificationManager.handleIncomingControl(notification: controlNotification)

        XCTAssertNil(broadcasterChannel.lastPushedEvent)
    }

    func testIncomingControlStreamingDisabled() {
        // making channel pri unavailable
        var n1 = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 1))
        n1.channel = kControlPriChannel
        n1.timestamp = 50
        notificationManager.handleIncomingPresenceEvent(notification: n1)

        // reseting pushed event
        broadcasterChannel.lastPushedEvent = nil
        let controlNotification = ControlNotification(type: .control, controlType: .streamingDisabled)
        notificationManager.handleIncomingControl(notification: controlNotification)

        let streamEvents = telemetryProducer.streamingEvents

        XCTAssertEqual(SyncStatusEvent.pushSubsystemDisabled, broadcasterChannel.lastPushedEvent)
        XCTAssertNotNil(streamEvents[.streamingStatus])
    }

    override func tearDown() {}
}
