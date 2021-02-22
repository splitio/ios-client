//
//  SyncManagerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 08/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SyncManagerTest: XCTestCase {

    var pushManager: PushNotificationManagerStub!
    var broadcasterChannel: PushManagerEventBroadcasterStub!
    var synchronizer: SynchronizerStub!
    var syncManager: SyncManager!
    let splitConfig = SplitClientConfig()
    var retryTimer: BackoffCounterTimerStub!

    override func setUp() {
        pushManager = PushNotificationManagerStub()
        broadcasterChannel = PushManagerEventBroadcasterStub()
        synchronizer = SynchronizerStub()
        retryTimer = BackoffCounterTimerStub()
    }

    func testStartStreamingEnabled() {

        splitConfig.streamingEnabled = true
        syncManager = DefaultSyncManager(splitConfig: splitConfig, pushNotificationManager: pushManager,
                                         reconnectStreamingTimer: retryTimer,
                                         notificationHelper: DefaultNotificationHelper.instance,
                                         synchronizer: synchronizer, broadcasterChannel: broadcasterChannel)
        syncManager.start()

        XCTAssertTrue(synchronizer.loadAndSynchronizeSplitsCalled)
        XCTAssertTrue(synchronizer.loadMySegmentsFromCacheCalled)
        XCTAssertTrue(synchronizer.synchronizeMySegmentsCalled)
        XCTAssertNotNil(broadcasterChannel.registeredHandler)
        XCTAssertTrue(pushManager.startCalled)
        XCTAssertTrue(synchronizer.startPeriodicRecordingCalled)
        XCTAssertFalse(synchronizer.startPeriodicFetchingCalled)
    }

    func testStartStreamingDisabled() {

        splitConfig.streamingEnabled = false
        syncManager = DefaultSyncManager(splitConfig: splitConfig, pushNotificationManager: pushManager,
                                         reconnectStreamingTimer: retryTimer,
                                         notificationHelper: DefaultNotificationHelper.instance,
                                         synchronizer: synchronizer, broadcasterChannel: broadcasterChannel)
        syncManager.start()

        XCTAssertTrue(synchronizer.loadAndSynchronizeSplitsCalled)
        XCTAssertTrue(synchronizer.loadMySegmentsFromCacheCalled)
        XCTAssertTrue(synchronizer.synchronizeMySegmentsCalled)
        XCTAssertNil(broadcasterChannel.registeredHandler)
        XCTAssertFalse(pushManager.startCalled)
        XCTAssertTrue(synchronizer.startPeriodicRecordingCalled)
        XCTAssertTrue(synchronizer.startPeriodicFetchingCalled)
    }

    func testPushSubsystemUpReceived() {

        splitConfig.streamingEnabled = true
        syncManager = DefaultSyncManager(splitConfig: splitConfig, pushNotificationManager: pushManager,
                                         reconnectStreamingTimer: retryTimer,
                                         notificationHelper: DefaultNotificationHelper.instance,
                                         synchronizer: synchronizer, broadcasterChannel: broadcasterChannel)
        syncManager.start()
        broadcasterChannel.push(event: .pushSubsystemUp)

        XCTAssertTrue(synchronizer.stopPeriodicFetchingCalled)
    }

    func testPushSubsystemDownReceived() {

        splitConfig.streamingEnabled = true
        syncManager = DefaultSyncManager(splitConfig: splitConfig, pushNotificationManager: pushManager,
                                         reconnectStreamingTimer: retryTimer,
                                         notificationHelper: DefaultNotificationHelper.instance,
                                         synchronizer: synchronizer, broadcasterChannel: broadcasterChannel)
        syncManager.start()
        broadcasterChannel.push(event: .pushSubsystemDown)

        XCTAssertTrue(synchronizer.startPeriodicFetchingCalled)
    }

    func testPushRetryableError() {

        splitConfig.streamingEnabled = true
        syncManager = DefaultSyncManager(splitConfig: splitConfig, pushNotificationManager: pushManager,
                                         reconnectStreamingTimer: retryTimer,
                                         notificationHelper: DefaultNotificationHelper.instance,
                                         synchronizer: synchronizer, broadcasterChannel: broadcasterChannel)
        syncManager.start()
        broadcasterChannel.push(event: .pushRetryableError)

        XCTAssertTrue(synchronizer.startPeriodicFetchingCalled)
        XCTAssertTrue(pushManager.startCalled)
        XCTAssertFalse(pushManager.stopCalled)
    }

    func testPushNonRetryableError() {

        splitConfig.streamingEnabled = true
        syncManager = DefaultSyncManager(splitConfig: splitConfig, pushNotificationManager: pushManager,
                                         reconnectStreamingTimer: retryTimer,
                                         notificationHelper: DefaultNotificationHelper.instance,
                                         synchronizer: synchronizer, broadcasterChannel: broadcasterChannel)
        syncManager.start()

        // reseting start called value
        pushManager.startCalled = false
        broadcasterChannel.push(event: .pushNonRetryableError)

        XCTAssertTrue(synchronizer.startPeriodicFetchingCalled)
        XCTAssertFalse(pushManager.startCalled)
        XCTAssertTrue(pushManager.stopCalled)
    }

    func testStop() {

        splitConfig.streamingEnabled = true
        syncManager = DefaultSyncManager(splitConfig: splitConfig, pushNotificationManager: pushManager,
                                         reconnectStreamingTimer: retryTimer,
                                         notificationHelper: DefaultNotificationHelper.instance,
                                         synchronizer: synchronizer, broadcasterChannel: broadcasterChannel)
        syncManager.start()
        syncManager.stop()

        XCTAssertTrue(synchronizer.destroyCalled)
        XCTAssertTrue(pushManager.stopCalled)
    }

    override func tearDown() {

    }
}
