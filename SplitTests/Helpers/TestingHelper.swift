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
    static func createEvents(count: Int = 10) -> [EventDTO] {
        var events = [EventDTO]()
        for i in 0..<count {
            let event = EventDTO(trafficType: "name", eventType: "type")
            event.storageId = "event\(i)"
            event.key = "key1"
            event.eventTypeId = "type1"
            event.trafficTypeName = "name1"
            event.value = (i % 2 > 0 ? 1.0 : 0.0)
            event.timestamp = 1000
            event.properties = ["f": i]
            events.append(event)
        }
        return events
    }

    static func createImpressions(feature: String = "split", count: Int = 10) -> [Impression] {
        var impressions = [Impression]()
        for i in 0..<count {
            let impression = Impression()
            impression.storageId = "\(feature)_impression\(i)"
            impression.feature = feature
            impression.keyName = "key1"
            impression.treatment = "t1"
            impression.time = 1000
            impression.changeNumber = 1000
            impression.label = "t1"
            impression.attributes = ["pepe": 1]
            impressions.append(impression)
        }
        return impressions
    }

    static func createTestImpressions(count: Int = 10) -> [ImpressionsTest] {
        var impressions = [ImpressionsTest]()
        for _ in 0..<count {
            let impressionTest = try! Json.encodeFrom(json: "{\"testName\":\"T1\", \"keyImpressions\":[]}", to: ImpressionsTest.self)
            impressions.append(impressionTest)
        }
        return impressions
    }

    static func createSplit(name: String, trafficType: String = "t1", status: Status = .active) -> Split {
        let split = Split()
        split.name = name
        split.trafficTypeName = trafficType
        split.status = status
        return split
    }

    static func createTestDatabase(name: String) -> SplitDatabase {
        let queue = DispatchQueue(label: name, target: DispatchQueue.global())
        let helper = IntegrationCoreDataHelper.get(databaseName: "trackTestDb", dispatchQueue: queue)
        return CoreDataSplitDatabase(coreDataHelper: helper, dispatchQueue: queue)
    }

    static func createLegacyImpressionsFileContent(testCount: Int, impressionsPerTest: Int) -> String {
        var hits = [String: ImpressionsHit]()
        do {
            for i in 0..<testCount {
                let testName = "T\(i)"
                let impJson = try Json.encodeToJson(createImpressions(feature: testName, count: impressionsPerTest))
                let impressionTest = try Json.encodeFrom(json: "{\"testName\":\"\(testName)\", \"keyImpressions\":\(impJson)}", to: ImpressionsTest.self)
                let uId = "id\(i)"
                hits[uId] = ImpressionsHit(identifier: uId, impressions: [impressionTest])
            }
        } catch {
            return ""
        }

        let file = ImpressionsFile()
        file.currentHit = ImpressionsHit(identifier: "id\(testCount)", impressions: [])
        file.oldHits = hits
        return (try? Json.encodeToJson(file)) ?? ""
    }

    static func createLegacyEventsFileContent(count: Int) -> String {
        var hits = [String: EventsHit]()
        for i in 0..<count {
            let events = createEvents(count: count)
            let uId = "id\(i)"
            hits[uId] = EventsHit(identifier: uId, events: events)
        }

        let file = EventsFile()
        file.currentHit = EventsHit(identifier: "id\(count)", events: [])
        file.oldHits = hits
        return (try? Json.dynamicEncodeToJson(file)) ?? ""
    }
}
