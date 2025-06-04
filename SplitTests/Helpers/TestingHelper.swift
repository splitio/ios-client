//
//  TestingHelper.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 19/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

struct TestingHelper {

    static var testLogLevel: SplitLogLevel {
        return .verbose
    }

    static func basicStreamingConfig() -> SplitClientConfig {
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 3
        splitConfig.segmentsRefreshRate = 3
        splitConfig.impressionRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPerPush = 10
        splitConfig.eventsQueueSize = 100
        splitConfig.eventsPushRate = 3
        splitConfig.logLevel = .verbose
        return splitConfig
    }

    static func createEvents(count: Int = 10, timestamp: Int64 = 1000, randomId: Bool = false) -> [EventDTO] {
        var events = [EventDTO]()
        for i in 0..<count {
            let event = EventDTO(trafficType: "name", eventType: "type")
            event.storageId = randomId ? UUID().uuidString : "event\(i)"
            event.key = "key1"
            event.eventTypeId = "type1"
            event.trafficTypeName = "name1"
            event.value = (i % 2 > 0 ? 1.0 : 0.0)
            event.timestamp = timestamp
            event.properties = ["f": i]
            events.append(event)
        }
        return events
    }

    static func createImpressions(feature: String = "split", count: Int = 10, time: Int64 = 100) -> [Impression] {
        var impressions = [Impression]()
        for i in 0..<count {
            let impression = Impression()
            impression.storageId = "\(feature)_impression\(i)"
            impression.feature = feature
            impression.keyName = "key1"
            impression.treatment = "t1"
            impression.time = time
            impression.changeNumber = 1000
            impression.label = "t1"
            impression.attributes = ["pepe": 1]
            impressions.append(impression)
        }
        return impressions
    }

    static func createKeyImpressions(feature: String = "split", count: Int = 10, time: Int64 = 100) -> [KeyImpression] {
        var impressions = [KeyImpression]()
        for i in 0..<count {
            let impression = KeyImpression(featureName: feature,
                                           keyName: "key1",
                                           bucketingKey: nil,
                                           treatment: "t1",
                                           label: "t1",
                                           time: time,
                                           changeNumber: 1000,
                                           previousTime: nil,
                                           storageId:  "\(feature)_impression\(i)")
            impressions.append(impression)
        }
        return impressions
    }

    static func createTestImpressions(count: Int = 10) -> [ImpressionsTest] {
        var impressions = [ImpressionsTest]()
        for _ in 0..<count {
            let impressionTest = try! Json.decodeFrom(json: "{\"f\":\"T1\", \"i\":[]}", to: ImpressionsTest.self)
            impressions.append(impressionTest)
        }
        return impressions
    }

    static func createImpressionsCount(count: Int = 10, randomId: Bool = true) -> [ImpressionsCountPerFeature] {

        var counts = [ImpressionsCountPerFeature]()
        for i in 0..<count {
            var count = ImpressionsCountPerFeature(feature: "feature\(i)", timeframe: Date().unixTimestampInMiliseconds(), count: 1)
            if randomId {
                count.storageId = UUID().uuidString
            } else {
                count.storageId = "row_id_\(i)"
            }
            counts.append(count)
        }
        return counts
    }

    static func createSplit(name: String,
                            trafficType: String = "t1",
                            status: Status = .active,
                            sets: Set<String>? = nil) -> Split {

        let split = Split(name: name, trafficType: trafficType, status: status, sets: sets, json: "")
        split.isCompletelyParsed = true
        return split
    }

    static func createSplits() -> [Split] {
        var splits = [Split]()
        for i in 0..<10 {
            let split = Split(name: "feat_\(i)", trafficType: "tt_\(i)", status: .active, sets: nil, json: "")
            split.isCompletelyParsed = true
            splits.append(split)
        }
        return splits
    }

    static func buildSplit(name: String, treatment: String) -> Split {
        let change = IntegrationHelper.getChanges(fileName: "simple_split_change")
        change?.since = Int64(1)
        change?.till = Int64(1)
        let split = change!.splits[0]
        split.name = name
        if let partitions = split.conditions?[2].partitions {
            for (i, partition) in partitions.enumerated() {
                if 1 == i {
                    partition.treatment = treatment
                    partition.size = 100
                } else {
                    partition.treatment = "off"
                    partition.size = 0
                }
            }
        }
        return split
    }

    static func createTestDatabase(name: String, queue: DispatchQueue? = nil) -> SplitDatabase {
        let newQueue = queue ?? DispatchQueue(label: "testqueue", target: DispatchQueue.test)
        let helper = IntegrationCoreDataHelper.get(databaseName: name, dispatchQueue: newQueue)
        return CoreDataSplitDatabase(coreDataHelper: helper)
    }

    static func createTestDatabase(name: String, queue: DispatchQueue? = nil, helper: CoreDataHelper) -> SplitDatabase {
        return CoreDataSplitDatabase(coreDataHelper: helper)
    }

    static func createTelemetryConfig() -> TelemetryConfig {
        return TelemetryConfig(streamingEnabled: true,
                               rates: nil, urlOverrides: nil, impressionsQueueSize: 9,
                               eventsQueueSize: 9, impressionsMode: 9, impressionsListenerEnabled: true,
                               httpProxyDetected: true, activeFactories: 1, redundantFactories: 12,
                               timeUntilReady: 9, timeUntilReadyFromCache: 5, nonReadyUsages: 2,
                               integrations: nil, tags: nil)
    }

    static func createTelemetryStats() -> TelemetryStats {
        return TelemetryStats(lastSynchronization: nil, methodLatencies: nil, methodExceptions: nil, httpErrors: nil, httpLatencies: nil, tokenRefreshes: 1, authRejections: 1, impressionsQueued: 1, impressionsDeduped: 1, impressionsDropped: 1, splitCount: 1, segmentCount: 1, segmentKeyCount: 2, sessionLengthMs: 88888, eventsQueued: 1, eventsDropped: 1, streamingEvents: nil, tags: nil, updatesFromSse: TelemetryUpdatesFromSse(splits: 10, mySegments: 20))
    }

    static func createUniqueKeys(keyCount: Int = 5, featureCount: Int = 20) -> UniqueKeys {
        var allKeys = [UniqueKey]()
        for k in 0..<keyCount {
            var features = Set<String>()
            for i in 0..<featureCount {
                features.insert("feature\(i)")
            }
            let uniqueKey = UniqueKey(userKey: "key\(k)", features: features)
            uniqueKey.storageId = "rowid_\(k)"
            allKeys.append(uniqueKey)
        }
        return UniqueKeys(keys: allKeys)
    }

    static func createStorageContainer() -> SplitStorageContainer {
        return SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "pepe"),
                                     splitsStorage: SplitsStorageStub(),
                                     persistentSplitsStorage: PersistentSplitsStorageStub(),
                                     impressionsStorage: ImpressionsStorageStub(),
                                     persistentImpressionsStorage: PersistentImpressionsStorageStub(),
                                     impressionsCountStorage: PersistentImpressionsCountStorageStub(),
                                     eventsStorage: EventsStorageStub(),
                                     persistentEventsStorage: PersistentEventsStorageStub(),
                                     telemetryStorage: TelemetryStorageStub(),
                                     mySegmentsStorage: MySegmentsStorageStub(),
                                     myLargeSegmentsStorage: MySegmentsStorageStub(),
                                     attributesStorage: AttributesStorageStub(),
                                     uniqueKeyStorage: PersistentUniqueKeyStorageStub(),
                                     flagSetsCache: FlagSetsCacheMock(),
                                     persistentHashedImpressionsStorage: PersistentHashedImpressionStorageMock(),
                                     hashedImpressionsStorage: HashedImpressionsStorageMock(),
                                     generalInfoStorage: GeneralInfoStorageMock(),
                                     ruleBasedSegmentsStorage: RuleBasedSegmentsStorageStub(),
                                     persistentRuleBasedSegmentsStorage: PersistentRuleBasedSegmentsStorageStub())
    }

    static func createApiFacade() -> SplitApiFacade {
        return try! SplitApiFacade.builder()
            .setUserKey("userKey")
            .setRestClient(RestClientStub())
            .setSplitConfig(SplitClientConfig())
            .setEventsManager(SplitEventsManagerStub())
            .setStreamingHttpClient(HttpClientMock(session: HttpSessionMock()))
            .build()
    }

    static func buildSegmentsChange(count: Int64 = 5,
                                    msAscOrder: Bool = true,
                                    mlsAscOrder: Bool = true,
                                    segmentsChanged: Bool = false) -> [AllSegmentsChange] {
        // Eventualy cn will be greater than the first
        let baseCn: Int64 = 100
        let lastMsCn = baseCn * count + 1
        let lastMlsCn = baseCn * count + 1

        var msC: Int64 = (msAscOrder ? 0 : lastMsCn - 1)
        var mlsC: Int64 = (mlsAscOrder ? 0: lastMlsCn - 1)
        let msSum: Int64 = (msAscOrder ? 1: -1) * baseCn
        let mlsSum: Int64 = (mlsAscOrder ? 1: -1) * baseCn
        var msSeg = ["s1", "s2"]
        var mlsSeg = ["ls1", "ls2"]
        var res = [AllSegmentsChange]()
        for _ in 0..<count-1 {
            msC+=msSum
            mlsC+=mlsSum
            res.append(newAllSegmentsChange(ms: msSeg, msCn: msC,
                                            mls: mlsSeg, mlsCn: mlsC))
        }
        if segmentsChanged {
            msSeg.append("s3")
            mlsSeg.append("sl3")
        }
        res.append(newAllSegmentsChange(ms: msSeg, msCn: lastMsCn,
                                        mls: mlsSeg, mlsCn: lastMlsCn))

        return res
    }

    static func newSegmentChange(_ segments: [String] = ["s1", "s2"], cn changeNumber: Int64 = -1) -> SegmentChange {
        return SegmentChange(segments: segments, changeNumber: changeNumber)
    }

    static func newAllSegmentsChange(msChange: SegmentChange, mlsChange: SegmentChange) -> AllSegmentsChange {
        return AllSegmentsChange(mySegmentsChange: msChange,
                                 myLargeSegmentsChange: mlsChange)
    }

    static func newAllSegmentsChange(ms: [String] = ["s1", "s1"], msCn: Int64 = -1,
                                     mls: [String] = ["ls1", "ls2"], mlsCn: Int64 = -1) -> AllSegmentsChange {
        let msChange = newSegmentChange(ms, cn: msCn)
        let mlsChange = newSegmentChange(mls, cn: mlsCn)
        return newAllSegmentsChange(msChange: msChange, mlsChange: mlsChange)
    }

    static func segmentsSyncResult(_ result: Bool = true,
                                   msCn: Int64 = 300, mlsCn: Int64 = 400,
                                   msUpd: Bool = true, mlsUpd: Bool = true) -> SegmentsSyncResult {
        return SegmentsSyncResult(success: result,
                                  msChangeNumber: msCn, mlsChangeNumber: mlsCn,
                                  msUpdated: msUpd, mlsUpdated: mlsUpd)
    }

    static func newAllSegmentsChangeJson(ms: [String] = ["s1", "s1"], msCn: Int64? = nil,
                                         mls: [String] = ["ls1", "ls2"], mlsCn: Int64? = nil) -> String {
        let msChange = SegmentChange(segments: ms, changeNumber: msCn)
        let mlsChange = SegmentChange(segments: mls, changeNumber: mlsCn)
        return try! Json.encodeToJson(newAllSegmentsChange(msChange: msChange, mlsChange: mlsChange))
    }

    static func createRuleBasedSegment(name: String = "test_rbs", trafficTypeName: String = "user", changeNumber: Int64 = 1000, status: Status = .active, conditions: [Condition]? = nil, excluded: Excluded? = nil) -> RuleBasedSegment {
        let segment = RuleBasedSegment(name: name, trafficTypeName: trafficTypeName, changeNumber: changeNumber, status: status, conditions: conditions, excluded: excluded)
        segment.isParsed = true
        return segment
    }
}
