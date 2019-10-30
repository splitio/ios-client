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
    static var mockEndPoint: String {
        return "http://localhost:8080"
    }

    static var emptyMySegments: String {
        return "{\"mySegments\":[]}"
    }

    static var emptySplitChanges: String {
        return "{\"splits\":[], \"since\": 9567456937865, \"till\": 9567456937869 }"
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
