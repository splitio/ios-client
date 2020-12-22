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
}
