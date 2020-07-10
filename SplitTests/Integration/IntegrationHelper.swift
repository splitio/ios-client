//
//  IntegrationHelper.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 01/10/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

class IntegrationHelper {

    static var mockServiceEndpoint: ServiceEndpoints {
        return ServiceEndpoints.builder().set(sdkEndpoint: mockEndPoint).set(eventsEndpoint: mockEndPoint).build()
    }

    static var dummyApiKey: String {
        return "99049fd8653247c5ea42bc3c1ae2c6a42bc3"
    }

    static var dummyFolderName: String {
        return "2a1099049fd8653247c5ea42bOIajMRhH0R0FcBwJZM4ca7zj6HAq1ZDS"
    }

    static var dummyUserKey: String {
        return "CUSTOMER_ID"
    }

    static var mockEndPoint: String {
        return "http://localhost:8080"
    }

    static var emptyMySegments: String {
        return "{\"mySegments\":[]}"
    }

    static var emptySplitChanges: String {
        return "{\"splits\":[], \"since\": 9567456937865, \"till\": 9567456937869 }"
    }

    static func emptySplitChanges(since: Int, till: Int) -> String {
        return "{\"splits\":[], \"since\": \(since), \"till\": \(till) }"
    }

    static func dummyImpressions() -> String {
        return """
        [{\"testName\": \"test1\", \"keyImpressions\":[
        {
        \"feature\": \"test1\",
        \"keyName\": \"thekey\",
        \"treatment\": \"on\",
        \"timestamp\": 111,
        \"changeNumber\": 999,
        \"label\": \"default rule\"
        }
        ]}]
        """
    }

    static func buildImpressionKey(impression: Impression) -> String {
        return buildImpressionKey(key: impression.keyName!, splitName: impression.feature!, treatment: impression.treatment!)
    }

    static func buildImpressionKey(key: String, splitName: String, treatment: String) -> String {
        return "(\(key)_\(splitName)_\(treatment)"
    }

    static func impressionsFromHit(request: ClientRequest) throws -> [ImpressionsTest] {
        return try buildImpressionsFromJson(content: request.data!)
    }

    static func buildImpressionsFromJson(content: String) throws -> [ImpressionsTest] {
        return try Json.encodeFrom(json: content, to: [ImpressionsTest].self)
    }

    static func buildEventsFromJson(content: String) throws -> [EventDTO] {
        return try Json.dynamicEncodeFrom(json: content, to: [EventDTO].self)
    }

    static func getTrackEventBy(value: Double, trackHits: [ClientRequest]) -> EventDTO? {
        let hits = trackHits
        for req in hits {
            var lastEventHitEvents: [EventDTO] = []
            do {
                lastEventHitEvents = try buildEventsFromJson(content: req.data!)
            } catch {
                print("error: \(error)")
            }
            let events = lastEventHitEvents.filter { $0.value == value }
            if events.count > 0 {
                return events[0]
            }
        }
        return nil
    }
}
