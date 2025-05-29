//
//  SyncManagerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 08/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class SyncManagerTest: XCTestCase {
    var pushManager: PushNotificationManagerStub!
    var broadcasterChannel: SyncEventBroadcasterStub!
    var synchronizer: SynchronizerStub!
    var syncManager: SyncManager!
    var splitConfig = SplitClientConfig()
    var retryTimer: BackoffCounterTimerStub!
    var syncGuardian: SyncGuardianStub!

    override func setUp() {
        syncGuardian = SyncGuardianStub()
        pushManager = PushNotificationManagerStub()
        broadcasterChannel = SyncEventBroadcasterStub()
        synchronizer = SynchronizerStub()
        retryTimer = BackoffCounterTimerStub()
    }

    func testStartStreamingEnabled() {
        splitConfig.streamingEnabled = true
        syncManager = createSyncManager()
        syncManager.start()
        broadcasterChannel.push(event: .splitLoadedFromCache)

        XCTAssertTrue(synchronizer.loadAndSynchronizeSplitsCalled)
        XCTAssertTrue(synchronizer.loadMySegmentsFromCacheCalled)
        XCTAssertTrue(synchronizer.synchronizeMySegmentsCalled)
        XCTAssertNotNil(broadcasterChannel.registeredHandler)
        XCTAssertTrue(pushManager.startCalled)
        XCTAssertTrue(synchronizer.startRecordingUserDataCalled)
        XCTAssertFalse(synchronizer.startPeriodicFetchingCalled)
    }

    func testStartStreamingDisabled() {
        splitConfig.streamingEnabled = false
        syncManager = createSyncManager()
        syncManager.start()
        broadcasterChannel.push(event: .splitLoadedFromCache)

        XCTAssertTrue(synchronizer.loadAndSynchronizeSplitsCalled)
        XCTAssertTrue(synchronizer.loadMySegmentsFromCacheCalled)
        XCTAssertTrue(synchronizer.synchronizeMySegmentsCalled)
        XCTAssertNotNil(broadcasterChannel.registeredHandler)
        XCTAssertFalse(pushManager.startCalled)
        XCTAssertTrue(synchronizer.startRecordingUserDataCalled)
        XCTAssertTrue(synchronizer.startPeriodicFetchingCalled)
    }

    func testStartSingleModeStreamingEnabled() {
        singleModeStartTest(streamingEnabled: true)
    }

    func testStartSingleModeStreamingDisabled() {
        singleModeStartTest(streamingEnabled: false)
    }

    func singleModeStartTest(streamingEnabled: Bool) {
        splitConfig.streamingEnabled = streamingEnabled
        splitConfig.syncEnabled = false
        syncManager = createSyncManager()
        syncManager.start()
        broadcasterChannel.push(event: .splitLoadedFromCache)

        XCTAssertTrue(synchronizer.loadAndSynchronizeSplitsCalled)
        XCTAssertTrue(synchronizer.loadMySegmentsFromCacheCalled)
        XCTAssertTrue(synchronizer.synchronizeMySegmentsCalled)
        XCTAssertNotNil(broadcasterChannel.registeredHandler)
        XCTAssertFalse(pushManager.startCalled)
        XCTAssertFalse(synchronizer.startPeriodicFetchingCalled)
        XCTAssertTrue(synchronizer.startRecordingUserDataCalled)
    }

    func testPushSubsystemUpReceived() {
        splitConfig.streamingEnabled = true
        syncManager = createSyncManager()
        syncManager.start()
        broadcasterChannel.push(event: .pushSubsystemUp)

        XCTAssertTrue(synchronizer.stopPeriodicFetchingCalled)
    }

    func testPushSubsystemDownReceived() {
        splitConfig.streamingEnabled = true
        syncManager = createSyncManager()
        syncManager.start()
        broadcasterChannel.push(event: .pushSubsystemDown)

        XCTAssertTrue(synchronizer.startPeriodicFetchingCalled)
    }

    func testPushRetryableError() {
        splitConfig.streamingEnabled = true
        syncManager = createSyncManager()
        syncManager.start()
        broadcasterChannel.push(event: .splitLoadedFromCache)
        broadcasterChannel.push(event: .pushRetryableError)

        XCTAssertTrue(synchronizer.startPeriodicFetchingCalled)
        XCTAssertTrue(pushManager.startCalled)
        XCTAssertFalse(pushManager.stopCalled)
    }

    func testPushNonRetryableError() {
        splitConfig.streamingEnabled = true
        syncManager = createSyncManager()
        syncManager.start()

        // reseting start called value
        pushManager.startCalled = false
        broadcasterChannel.push(event: .pushNonRetryableError)

        XCTAssertTrue(synchronizer.startPeriodicFetchingCalled)
        XCTAssertFalse(pushManager.startCalled)
        XCTAssertTrue(pushManager.stopCalled)
    }

    func testPushReset() {
        splitConfig.streamingEnabled = true
        syncManager = createSyncManager()
        syncManager.start()

        // reseting start called value
        pushManager.startCalled = false
        broadcasterChannel.push(event: .pushReset)

        XCTAssertTrue(pushManager.disconnectCalled)
        XCTAssertTrue(retryTimer.scheduleCalled)
    }

    func testStop() {
        splitConfig.streamingEnabled = true
        syncManager = createSyncManager()
        syncManager.start()
        syncManager.stop()

        XCTAssertTrue(synchronizer.destroyCalled)
        XCTAssertTrue(pushManager.stopCalled)
    }

    func testPauseResume() {
        splitConfig.streamingEnabled = true
        syncManager = createSyncManager()

        syncManager.start()
        syncManager.pause()
        syncManager.resume()

        // macOS doesn't have to pause sdk process
        // when is no active
        #if !os(macOS)
            XCTAssertTrue(pushManager.pauseCalled)
            XCTAssertTrue(pushManager.resumeCalled)
            XCTAssertTrue(synchronizer.pauseCalled)
            XCTAssertTrue(synchronizer.resumeCalled)
        #else
            XCTAssertFalse(pushManager.pauseCalled)
            XCTAssertFalse(pushManager.resumeCalled)
            XCTAssertFalse(synchronizer.pauseCalled)
            XCTAssertFalse(synchronizer.resumeCalled)
        #endif
    }

    func testPushDelayReceived() {
        splitConfig.streamingEnabled = true
        syncGuardian.maxSyncPeriod = -1
        syncManager = createSyncManager()
        syncManager.start()
        broadcasterChannel.push(event: .pushDelayReceived(delaySeconds: 5))

        XCTAssertEqual(5000, syncGuardian.maxSyncPeriod)
    }

    func testSyncExecutedReceived() {
        splitConfig.streamingEnabled = true
        syncGuardian.updateLastSyncTimestampCalled = false
        syncManager = createSyncManager()
        syncManager.start()
        broadcasterChannel.push(event: .syncExecuted)

        XCTAssertTrue(syncGuardian.updateLastSyncTimestampCalled)
    }

    func testCredentialPinnedFailNotification() {
        let endpoints = ["auth.com", "stream.com", "sdk.com", "tele.com", "event.com"]

        let epConfig = ServiceEndpoints.builder()
            .set(authServiceEndpoint: endpoints[0])
            .set(sdkEndpoint: endpoints[2])
            .set(streamingServiceEndpoint: endpoints[1])
            .set(telemetryServiceEndpoint: endpoints[3])
            .set(eventsEndpoint: endpoints[4])
            .build()
        splitConfig.serviceEndpoints = epConfig
        splitConfig.streamingEnabled = true
        var exp: XCTestExpectation?
        let nHelper = DefaultNotificationHelper.instance
        nHelper.addObserver(for: .pinnedCredentialValidationFail) { host in
            exp?.fulfill()
        }
        for (oIndex, oEndpoint) in endpoints.enumerated() {
            exp = XCTestExpectation()
            synchronizer = SynchronizerStub()
            pushManager = PushNotificationManagerStub()
            syncManager = createSyncManager()
            syncManager.start()
            nHelper.post(notification: .pinnedCredentialValidationFail, info: oEndpoint as AnyObject)
            wait(for: [exp!], timeout: 5.0)

            print("Evaluating: \(oEndpoint)")
            switch oIndex {
            case 0, 1:
                XCTAssertTrue(pushManager.stopCalled)
                XCTAssertTrue(synchronizer.startPeriodicFetchingCalled)
                XCTAssertFalse(synchronizer.disableSdkCalled)
                XCTAssertFalse(synchronizer.disableEventsCalled)
                XCTAssertFalse(synchronizer.disableTelemetryCalled)
            case 2:
                XCTAssertFalse(pushManager.stopCalled)
                XCTAssertFalse(synchronizer.startPeriodicFetchingCalled)
                XCTAssertTrue(synchronizer.disableSdkCalled)
                XCTAssertFalse(synchronizer.disableEventsCalled)
                XCTAssertFalse(synchronizer.disableTelemetryCalled)
            case 3:
                XCTAssertFalse(pushManager.stopCalled)
                XCTAssertFalse(synchronizer.startPeriodicFetchingCalled)
                XCTAssertFalse(synchronizer.disableSdkCalled)
                XCTAssertFalse(synchronizer.disableEventsCalled)
                XCTAssertTrue(synchronizer.disableTelemetryCalled)
            case 4:
                XCTAssertFalse(pushManager.stopCalled)
                XCTAssertFalse(synchronizer.startPeriodicFetchingCalled)
                XCTAssertFalse(synchronizer.disableSdkCalled)
                XCTAssertTrue(synchronizer.disableEventsCalled)
                XCTAssertFalse(synchronizer.disableTelemetryCalled)
            default:
                print("nones")
            }
        }
    }

    private func createSyncManager() -> SyncManager {
        return DefaultSyncManager(
            splitConfig: splitConfig,
            pushNotificationManager: pushManager,
            reconnectStreamingTimer: retryTimer,
            notificationHelper: DefaultNotificationHelper.instance,
            synchronizer: synchronizer,
            syncGuardian: syncGuardian,
            broadcasterChannel: broadcasterChannel)
    }
}
