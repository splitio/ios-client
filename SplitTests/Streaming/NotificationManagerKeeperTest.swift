//
//  NotificationManagerKeeperTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 02/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class NotificationManagerKeeperTest: XCTestCase {

    private let kControlPriChannel = "[?occupancy=metrics.publishers]control_pri"
    private let kControlSecChannel = "[?occupancy=metrics.publishers]control_sec"

    var broadcasterChannel: PushManagerEventBroadcasterStub!
    var notificationManager: NotificationManagerKeeper!

    override func setUp() {
        broadcasterChannel = PushManagerEventBroadcasterStub()
        notificationManager = DefaultNotificationManagerKeeper(broadcasterChannel: broadcasterChannel)
    }

    func testNoAvailablePublishers() {
        // Notification manager keeper start assuming one publisher in primary channel
        // Receiving 0 publishers in primary and having 0 in sec, should enable polling
        var notification = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 0))
        notification.channel = kControlPriChannel
        notification.timestamp = 100
        notificationManager.handleIncomingPresenceEvent(notification: notification)

        XCTAssertEqual(PushStatusEvent.pushSubsystemDown, broadcasterChannel.lastPushedEvent)
    }

    func testNoAvailablePublishersOldTimestamp() {
        // Notification manager keeper start assuming one publisher in primary channel
        // Receiving 0 (old timestamp) should not enable polling
        var notification = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 0))
        notification.channel = kControlPriChannel
        notification.timestamp = 0
        notificationManager.handleIncomingPresenceEvent(notification: notification)

        XCTAssertNil(broadcasterChannel.lastPushedEvent)
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

        XCTAssertNil(broadcasterChannel.lastPushedEvent)
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

        XCTAssertEqual(PushStatusEvent.pushSubsystemUp, broadcasterChannel.lastPushedEvent)
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
        let controlNotification = ControlNotification(type: .control, controlType: .streamingEnabled)
        notificationManager.handleIncomingControl(notification: controlNotification)

        XCTAssertEqual(PushStatusEvent.pushSubsystemUp, broadcasterChannel.lastPushedEvent)
    }

    func testIncomingControlStreamingEnabledNoPublishers() {
        // making channel pri unavailable
        var n1 = OccupancyNotification(metrics: OccupancyNotification.Metrics(publishers: 0))
        n1.channel = kControlPriChannel
        n1.timestamp = 50
        notificationManager.handleIncomingPresenceEvent(notification: n1)

        // reseting pushed event
        broadcasterChannel.lastPushedEvent = nil
        let controlNotification = ControlNotification(type: .control, controlType: .streamingEnabled)
        notificationManager.handleIncomingControl(notification: controlNotification)

        XCTAssertNil(broadcasterChannel.lastPushedEvent)
    }

    override func tearDown() {

    }
}
