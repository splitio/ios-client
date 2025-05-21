//
//  SynchronizerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 10-03-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SynchronizerTest: XCTestCase {

    var mySegmentsSyncWorker: RetryableSyncWorkerStub!
    var persistentSplitsStorage: PersistentSplitsStorageStub!
    var mySegmentsStorage: ByKeyMySegmentsStorageStub!

    var synchronizer: Synchronizer!

    var eventsManager: SplitEventsManagerStub!
    var telemetryProducer: TelemetryStorageStub!
    var byKeyApiFacade: ByKeyFacadeMock!
    var impressionsTracker: ImpressionsTrackerStub!
    var eventsSynchronizer: EventsSynchronizerStub!
    var telemetrySynchronizer: TelemetrySynchronizerStub!

    var fFlagsSynchronizer: FeatureFlagsSynchronizerStub!

    let userKey = "CUSTOMER_KEY"

    var splitConfig: SplitClientConfig!
    var flagSetsCache: FlagSetsCacheMock!

    override func setUp() {
        synchronizer = buildSynchronizer()
    }

    func buildSynchronizer(impressionsAccumulator: RecorderFlushChecker? = nil,
                           eventsAccumulator: RecorderFlushChecker? = nil,
                           syncEnabled: Bool = true) -> Synchronizer {

        eventsManager = SplitEventsManagerStub()
        mySegmentsSyncWorker = RetryableSyncWorkerStub()

        impressionsTracker = ImpressionsTrackerStub()
        eventsSynchronizer = EventsSynchronizerStub()

        mySegmentsStorage = ByKeyMySegmentsStorageStub()
        telemetryProducer = TelemetryStorageStub()
        flagSetsCache = FlagSetsCacheMock()

        let storageContainer = SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "pepe"),
                                                     splitsStorage: SplitsStorageStub(),
                                                     persistentSplitsStorage: PersistentSplitsStorageStub(),
                                                     impressionsStorage: ImpressionsStorageStub(),
                                                     persistentImpressionsStorage: PersistentImpressionsStorageStub(),
                                                     impressionsCountStorage: PersistentImpressionsCountStorageStub(),
                                                     eventsStorage: EventsStorageStub(),
                                                     persistentEventsStorage: PersistentEventsStorageStub(),
                                                     telemetryStorage: telemetryProducer,
                                                     mySegmentsStorage: MySegmentsStorageStub(),
                                                     myLargeSegmentsStorage: MySegmentsStorageStub(),
                                                     attributesStorage: AttributesStorageStub(),
                                                     uniqueKeyStorage: PersistentUniqueKeyStorageStub(),
                                                     flagSetsCache: flagSetsCache,
                                                     persistentHashedImpressionsStorage: PersistentHashedImpressionStorageMock(),
                                                     hashedImpressionsStorage: HashedImpressionsStorageMock(),
                                                     generalInfoStorage: GeneralInfoStorageMock(),
                                                     ruleBasedSegmentsStorage: RuleBasedSegmentsStorageStub(),
                                                     persistentRuleBasedSegmentsStorage: PersistentRuleBasedSegmentsStorageStub())

        splitConfig =  SplitClientConfig()
        splitConfig.syncEnabled = syncEnabled
        splitConfig.sync = SyncConfig.builder().addSplitFilter(SplitFilter.byName(["SPLIT1"])).build()

        byKeyApiFacade = ByKeyFacadeMock()

        telemetrySynchronizer = TelemetrySynchronizerStub()

        fFlagsSynchronizer = FeatureFlagsSynchronizerStub()

        synchronizer = DefaultSynchronizer(splitConfig: splitConfig,
                                           defaultUserKey: userKey,
                                           featureFlagsSynchronizer: fFlagsSynchronizer,
                                           telemetrySynchronizer: telemetrySynchronizer,
                                           byKeyFacade: byKeyApiFacade,
                                           splitStorageContainer: storageContainer,
                                           impressionsTracker: impressionsTracker,
                                           eventsSynchronizer: eventsSynchronizer,
                                           splitEventsManager: eventsManager)
        return synchronizer
    }

    func testSyncAll() {

        synchronizer.syncAll()

        XCTAssertTrue(fFlagsSynchronizer.synchronizeCalled)
        XCTAssertTrue(byKeyApiFacade.syncAllCalled)
    }

    func testLoadSplits() {

        synchronizer.loadSplitsFromCache()

        XCTAssertTrue(fFlagsSynchronizer.loadCalled)
    }

    func testLoadMySegmentsFromCache() {

        synchronizer.loadMySegmentsFromCache(forKey: userKey)

        ThreadUtils.delay(seconds: 0.2)

        XCTAssertTrue(byKeyApiFacade.loadMySegmentsFromCacheCalled[userKey] ?? false)
    }

    func testSynchronizeMySegments() {

        synchronizer.synchronizeMySegments(forKey: userKey)

        XCTAssertTrue(byKeyApiFacade.syncMySegmentsCalled[userKey] ?? false)
    }

    func testForceSynchronizeMySegments() {

        let cn = SegmentsChangeNumber(msChangeNumber: 100, mlsChangeNumber: 200)
        synchronizer.forceMySegmentsSync(forKey: userKey, changeNumbers: cn, delay: 5)

        XCTAssertEqual(byKeyApiFacade.forceMySegmentsCalledParams[userKey]?.segmentsCn.msChangeNumber, 100)
        XCTAssertEqual(byKeyApiFacade.forceMySegmentsCalledParams[userKey]?.segmentsCn.mlsChangeNumber, 200)
        XCTAssertEqual(byKeyApiFacade.forceMySegmentsCalledParams[userKey]?.delay, 5)
        XCTAssertTrue(byKeyApiFacade.forceMySegmentsSyncCalled[userKey] ?? false)
    }

    func testSynchronizeSplitsWithChangeNumber() {

        synchronizer.synchronizeSplits(changeNumber: 101)

        XCTAssertTrue(fFlagsSynchronizer.synchronizeNumberCalled)
    }

    func testStartPeriodicFetching() {

        synchronizer.startPeriodicFetching()

        XCTAssertTrue(fFlagsSynchronizer.startPeriodicSyncCalled)
        XCTAssertTrue(byKeyApiFacade.startPeriodicSyncCalled)
    }

    func testStartPeriodicFetchingSingleModeEnabled() {

        synchronizer = buildSynchronizer(syncEnabled: false)
        synchronizer.startPeriodicFetching()

        XCTAssertFalse(fFlagsSynchronizer.startPeriodicSyncCalled)
        XCTAssertFalse(byKeyApiFacade.startPeriodicSyncCalled)
    }

    func testUpdateSplitsSingleModeEnabled() {

        synchronizer = buildSynchronizer(syncEnabled: false)
        synchronizer.synchronizeSplits(changeNumber: -1)

        XCTAssertFalse(fFlagsSynchronizer.synchronizeCalled)
    }

    func testForceMySegmentsSyncSingleModeEnabled() {
        let syncKey = IntegrationHelper.dummyUserKey
        let cn = SegmentsChangeNumber(msChangeNumber: 100, mlsChangeNumber: 200)
        synchronizer = buildSynchronizer(syncEnabled: false)
        synchronizer.forceMySegmentsSync(forKey: syncKey, changeNumbers: cn, delay: 10)

        XCTAssertNil(byKeyApiFacade.forceMySegmentsSyncCalled[syncKey])
    }

    func testStopPeriodicFetching() {

        synchronizer.stopPeriodicFetching()

        XCTAssertTrue(fFlagsSynchronizer.stopPeriodicSyncCalled)
        XCTAssertTrue(byKeyApiFacade.stopPeriodicSyncCalled)
    }

    func testStartPeriodicRecordingUserData() {
        impressionsTracker.startCalled = false
        eventsSynchronizer.startCalled = false
        synchronizer.startRecordingUserData()

        XCTAssertTrue(impressionsTracker.startCalled)
        XCTAssertTrue(eventsSynchronizer.startCalled)
    }

    func testStopRecordingUserData() {
        impressionsTracker.startCalled = false
        eventsSynchronizer.startCalled = false

        synchronizer.stopRecordingUserData()

        XCTAssertTrue(impressionsTracker.stopCalled)
        XCTAssertTrue(eventsSynchronizer.stopCalled)
    }

    func testStartRecordingTelemetry() {
        telemetrySynchronizer.startCalled = false
        synchronizer.startRecordingTelemetry()

        XCTAssertTrue(telemetrySynchronizer.startCalled)
    }

    func testStopRecordingTelemetry() {
        telemetrySynchronizer.destroyCalled = true
        synchronizer.stopRecordingTelemetry()

        XCTAssertTrue(telemetrySynchronizer.destroyCalled)
    }

    func testStartByKey() {
        let key = Key(matchingKey: userKey)
        synchronizer.start(forKey: key)

        XCTAssertTrue(byKeyApiFacade.startSyncForKeyCalled[key] ?? false)
    }

    func testFlush() {

        synchronizer.flush()
        sleep(1)
        XCTAssertTrue(impressionsTracker.flushCalled)
        XCTAssertTrue(eventsSynchronizer.flushCalled)
    }

    func testDestroy() {


        synchronizer.synchronizeSplits(changeNumber: 101)
        synchronizer.synchronizeSplits(changeNumber: 102)

        synchronizer.destroy()

        XCTAssertTrue(fFlagsSynchronizer.destroyCalled)
        XCTAssertTrue(byKeyApiFacade.destroyCalled)
        XCTAssertTrue(byKeyApiFacade.destroyCalled)
    }

    func testEventPush() {


        for i in 0..<5 {
            synchronizer.pushEvent(event: EventDTO(trafficType: "t1", eventType: "e\(i)"))
        }


        ThreadUtils.delay(seconds: 1)
        XCTAssertTrue(eventsSynchronizer.pushCalled)

    }

    // When SDK endpoint credential validation fails
    // only Splits and MySegments sync should stop
    func testDisableSdkEndpoint() {
        synchronizer.disableSdk()
        XCTAssertTrue(fFlagsSynchronizer.destroyCalled)
        XCTAssertFalse(impressionsTracker.stopCalled)
        XCTAssertFalse(impressionsTracker.stopImpressionsCalled)
        XCTAssertFalse(impressionsTracker.stopUniqueKeysCalled)
        XCTAssertFalse(eventsSynchronizer.stopCalled)
        XCTAssertFalse(telemetrySynchronizer.destroyCalled)
    }

    // When telemetry endpoint is disabled (i.e. host is banned by credential validation fails)
    // all the services using that enpoint should be stopped
    // but the ones using other endpoints should continue working
    // Unique keys uses telemetry endpoint, so, it should be stopped too.
    func testDisableTelemetry() {
        // Simulate telemetry enabled
        splitConfig.telemetryConfigHelper = TelemetryConfigHelperStub.init(enabled: true)
        synchronizer.disableTelemetry()
        XCTAssertFalse(fFlagsSynchronizer.destroyCalled)
        XCTAssertFalse(impressionsTracker.stopCalled)
        XCTAssertFalse(impressionsTracker.stopImpressionsCalled)
        XCTAssertTrue(impressionsTracker.stopUniqueKeysCalled)
        XCTAssertFalse(eventsSynchronizer.stopCalled)
        XCTAssertTrue(telemetrySynchronizer.destroyCalled)
    }

    // When disabling events enpoint, Events and Impressions
    // services should be stopped.
    // Unique keys are sent to telemetry endpoint, so it should continue
    // working
    func testDisableEventsEndpoint() {
        synchronizer.disableEvents()
        XCTAssertFalse(fFlagsSynchronizer.destroyCalled)
        XCTAssertFalse(impressionsTracker.stopCalled)
        XCTAssertTrue(impressionsTracker.stopImpressionsCalled)
        XCTAssertFalse(impressionsTracker.stopUniqueKeysCalled)
        XCTAssertTrue(eventsSynchronizer.stopCalled)
        XCTAssertFalse(telemetrySynchronizer.destroyCalled)
    }

}
