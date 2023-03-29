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

    static func basicStreamingConfig() -> SplitClientConfig {
        let splitConfig: SplitClientConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 3
        splitConfig.segmentsRefreshRate = 3
        splitConfig.impressionRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPerPush = 10
        splitConfig.eventsQueueSize = 100
        splitConfig.eventsPushRate = 3
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
            let impressionTest = try! Json.encodeFrom(json: "{\"f\":\"T1\", \"i\":[]}", to: ImpressionsTest.self)
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

    static func createSplit(name: String, trafficType: String = "t1", status: Status = .active) -> Split {
        let split = Split()
        split.name = name
        split.trafficTypeName = trafficType
        split.status = status
        return split
    }

    static func createSplits() -> [Split] {
        var splits = [Split]()
        for i in 0..<10 {
            let split = Split()
            split.name = "feat_\(i)"
            split.trafficTypeName = "tt_\(i)"
            split.status = .active
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
        if let partitions = split.conditions?[1].partitions {
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
        let newQueue = queue ?? DispatchQueue(label: "testqueue", target: DispatchQueue.test)
        return CoreDataSplitDatabase(coreDataHelper: helper)
    }

    static func createTelemetryConfig() -> TelemetryConfig {
        return TelemetryConfig(streamingEnabled: true, rates: nil, urlOverrides: nil, impressionsQueueSize: 9,
                               eventsQueueSize: 9, impressionsMode: 9, impressionsListenerEnabled: true,
                               httpProxyDetected: true, activeFactories: 1, redundantFactories: 12,
                               timeUntilReady: 9, timeUntilReadyFromCache: 5, nonReadyUsages: 2,
                               integrations: nil, tags: nil)
    }

    static func createTelemetryStats() -> TelemetryStats {
        return TelemetryStats(lastSynchronization: nil, methodLatencies: nil, methodExceptions: nil, httpErrors: nil, httpLatencies: nil, tokenRefreshes: 1, authRejections: 1, impressionsQueued: 1, impressionsDeduped: 1, impressionsDropped: 1, splitCount: 1, segmentCount: 1, segmentKeyCount: 2, sessionLengthMs: 88888, eventsQueued: 1, eventsDropped: 1, streamingEvents: nil, tags: nil)
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
                                     fileStorage: FileStorageStub(),
                                     splitsStorage: SplitsStorageStub(),
                                     persistentSplitsStorage: PersistentSplitsStorageStub(),
                                     impressionsStorage: ImpressionsStorageStub(),
                                     persistentImpressionsStorage: PersistentImpressionsStorageStub(),
                                     impressionsCountStorage: PersistentImpressionsCountStorageStub(),
                                     eventsStorage: EventsStorageStub(),
                                     persistentEventsStorage: PersistentEventsStorageStub(),
                                     telemetryStorage: TelemetryStorageStub(),
                                     mySegmentsStorage: MySegmentsStorageStub(),
                                     attributesStorage: AttributesStorageStub(),
                                     uniqueKeyStorage: PersistentUniqueKeyStorageStub())
    }
}
