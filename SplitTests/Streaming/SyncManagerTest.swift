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

    override func setUp() {
        pushManager = PushNotificationManagerStub()
        broadcasterChannel = PushManagerEventBroadcasterStub()
        synchronizer = SynchronizerStub()
    }

    func testStartStreamingEnabled() {

        splitConfig.streamingEnabled = true
        syncManager = DefaultSyncManager(splitConfig: splitConfig, pushNotificationManager: pushManager,
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
                                         synchronizer: synchronizer, broadcasterChannel: broadcasterChannel)
        syncManager.start()
        broadcasterChannel.push(event: .pushSubsystemUp)

        XCTAssertTrue(synchronizer.stopPeriodicFetchingCalled)
    }

    func testPushSubsystemDownReceived() {

        splitConfig.streamingEnabled = true
        syncManager = DefaultSyncManager(splitConfig: splitConfig, pushNotificationManager: pushManager,
                                         synchronizer: synchronizer, broadcasterChannel: broadcasterChannel)
        syncManager.start()
        broadcasterChannel.push(event: .pushSubsystemDown)

        XCTAssertTrue(synchronizer.startPeriodicFetchingCalled)
    }

    override func tearDown() {

    }
}

