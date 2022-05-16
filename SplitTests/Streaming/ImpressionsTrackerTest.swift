//
//  ImpressionsTrackerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 13-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class ImpressionsTrackerTest: XCTestCase {
    var periodicImpressionsRecorderWorker: PeriodicRecorderWorkerStub!
    var impressionsRecorderWorker: RecorderWorkerStub!
    var impressionsTracker: ImpressionsTracker!
    var syncWorkerFactory: SyncWorkerFactoryStub!
    var telemetryProducer: TelemetryStorageStub!

    override func setUp() {
        periodicImpressionsRecorderWorker = PeriodicRecorderWorkerStub()
        impressionsRecorderWorker = RecorderWorkerStub()

        syncWorkerFactory = SyncWorkerFactoryStub()

                syncWorkerFactory.periodicImpressionsRecorderWorker = periodicImpressionsRecorderWorker
                syncWorkerFactory.impressionsRecorderWorker = impressionsRecorderWorker


                telemetryProducer = TelemetryStorageStub()


                let storageContainer = SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "pepe"),
                                                             fileStorage: FileStorageStub(),
                                                             splitsStorage: SplitsStorageStub(),
                                                             persistentSplitsStorage: PersistentSplitsStorageStub(),
                                                             impressionsStorage: PersistentImpressionsStorageStub(),
                                                             impressionsCountStorage: PersistentImpressionsCountStorageStub(),
                                                             eventsStorage: PersistentEventsStorageStub(),
                                                             telemetryStorage: telemetryProducer,
                                                             mySegmentsStorage: MySegmentsStorageStub(),
                                                             attributesStorage: AttributesStorageStub())

                let apiFacade = SplitApiFacade.builder()
                    .setUserKey("userKey")
                    .setRestClient(RestClientStub())
                    .setSplitConfig(SplitClientConfig())
                    .setEventsManager(SplitEventsManagerStub())
                    .setStreamingHttpClient(HttpClientMock(session: HttpSessionMock()))
                    .build()

        impressionsTracker = DefaultImpressionsTracker(splitConfig: SplitClientConfig(),
                                                       splitApiFacade: apiFacade,
                                                       storageContainer: storageContainer,
                                                       syncWorkerFactory: syncWorkerFactory,
                                                       impressionsSyncHelper: ImpressionsRecorderSyncHelper(impressionsStorage: PersistentImpressionsStorageStub(),
                                                                                                            accumulator: DefaultRecorderFlushChecker(maxQueueSize: 10, maxQueueSizeInBytes: 10)))
    }

//    func testImpressionPush() {
//        let impression = KeyImpression(featureName: "feature", keyName: "k1",
//                                       treatment: "t1", label: nil, time: 1,
//                                       changeNumber: 1)
//
//        for _ in 0..<5 {
//            synchronizer.pushImpression(impression: impression)
//        }
//
//
//        ThreadUtils.delay(seconds: 1)
//        XCTAssertEqual(1, telemetryProducer.impressions[.queued])
//        XCTAssertEqual(4, telemetryProducer.impressions[.deduped])
//    }

    override func tearDown() {
    }
}

