//
//  RestClientStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 23/04/2019.
//  Copyright © 2019 Split. All rights reserved.
//

@testable import Split
import XCTest

protocol RestClientTest {
    func update(segments: [AllSegmentsChange]?)
    func update(change: TargetingRulesChange?)
    func update(changes: [TargetingRulesChange])
    func update(response: SseAuthenticationResponse?)
    func updateFailedSseAuth(error: Error)
}

class RestClientStub: SplitApiRestClient {
    private var sseAuthResult: DataResult<SseAuthenticationResponse>?
    private var segments: [AllSegmentsChange]?
    private var largeSegments: [SegmentChange]?
    private var splitChanges: [TargetingRulesChange] = []
    private var sendTrackEventsCount = 0
    private var sendImpressionsCount = 0
    private var sendImpressionsCountCount = 0

    var sendTelemetryConfigCount = 0
    var sendTelemetryStatsCount = 0
    var sendUniqueKeysCount = 0
    var isServerAvailable = true
    private var splitChangeHitIndex = 0
    private var segmentsChangeHitIndex = 0
    private var largeSegmentsChangeHitIndex = 0

    func getSendTrackEventsCount() -> Int {
        return sendTrackEventsCount
    }

    func getSendImpressionsCount() -> Int {
        return sendImpressionsCount
    }

    func getSendImpressionsCountCount() -> Int {
        return sendImpressionsCountCount
    }
}

extension RestClientStub: RestClient {
    func isServerAvailable(_ url: URL) -> Bool { return isServerAvailable }
    func isServerAvailable(path url: String) -> Bool { return isServerAvailable }
    func isEventsServerAvailable() -> Bool { return isServerAvailable }
    func isSdkServerAvailable() -> Bool { return isServerAvailable }
}

extension RestClientStub: RestClientSplitChanges {
    func getSplitChanges(
        since: Int64,
        rbSince: Int64?,
        till: Int64?,
        headers: HttpHeaders?,
        spec: String = Spec.flagsSpec,
        completion: @escaping (DataResult<TargetingRulesChange>) -> Void) {
        if splitChanges.isEmpty {
            completion(DataResult.success(value: nil))
            return
        }

        let rbSince = rbSince ?? -1
        let hit = splitChangeHitIndex
        splitChangeHitIndex += 1
        if hit <= splitChanges.count - 1 {
            let splitChange = splitChanges[hit]
            let targetingRulesChange = splitChange
            completion(DataResult.success(value: targetingRulesChange))
            return
        }

        let splitChange = splitChanges[splitChanges.count - 1]
        completion(DataResult.success(value: splitChange))
    }
}

extension RestClientStub: RestClientMySegments {
    func getMySegments(
        user: String,
        till: Int64?,
        headers: [String: String]?,
        completion: @escaping (DataResult<AllSegmentsChange>) -> Void) {
        if segments?.isEmpty == true {
            completion(DataResult.success(value: nil))
            return
        }
        let hit = segmentsChangeHitIndex
        segmentsChangeHitIndex += 1
        if hit <= segments?.count ?? 0 - 1 {
            completion(DataResult.success(value: segments?[hit]))
            return
        }

        completion(DataResult.success(value: segments?[segmentsChangeHitIndex]))
    }
}

extension RestClientStub: RestClientTrackEvents {
    func sendTrackEvents(events: [EventDTO], completion: @escaping (DataResult<EmptyValue>) -> Void) {
        sendTrackEventsCount += 1
        completion(DataResult.success(value: nil))
    }
}

extension RestClientStub: RestClientImpressions {
    func sendImpressions(impressions: [ImpressionsTest], completion: @escaping (DataResult<EmptyValue>) -> Void) {
        sendImpressionsCount += 1
        completion(DataResult.success(value: nil))
    }
}

extension RestClientStub: RestClientImpressionsCount {
    func send(counts: ImpressionsCount, completion: @escaping (DataResult<EmptyValue>) -> Void) {
        sendImpressionsCountCount += 1
        completion(DataResult.success(value: nil))
    }
}

extension RestClientStub: RestClientSseAuthenticator {
    func authenticate(userKeys: [String], completion: @escaping (DataResult<SseAuthenticationResponse>) -> Void) {
        completion(sseAuthResult!)
    }
}

extension RestClientStub: RestClientTelemetryConfig {
    func send(config: TelemetryConfig, completion: @escaping (DataResult<EmptyValue>) -> Void) {
        sendTelemetryConfigCount += 1
        completion(DataResult.success(value: nil))
    }
}

extension RestClientStub: RestClientTelemetryStats {
    func send(stats: TelemetryStats, completion: @escaping (DataResult<EmptyValue>) -> Void) {
        sendTelemetryStatsCount += 1
        completion(DataResult.success(value: nil))
    }
}

extension RestClientStub: RestClientUniqueKeys {
    func send(uniqueKeys: UniqueKeys, completion: @escaping (DataResult<EmptyValue>) -> Void) {
        sendUniqueKeysCount += 1
        completion(DataResult.success(value: nil))
    }
}

extension RestClientStub: RestClientTest {
    func update(changes: [TargetingRulesChange]) {
        splitChanges = changes
    }

    func update(segments: [AllSegmentsChange]?) {
        self.segments = segments
    }

    func update(largeSegments: [SegmentChange]?) {
        self.largeSegments = largeSegments
    }

    func update(change: TargetingRulesChange?) {
        if let change = change {
            splitChanges.append(change)

        } else {
            splitChanges.removeAll()
        }
    }

    func update(response: SseAuthenticationResponse?) {
        sseAuthResult = DataResult.success(value: response)
    }

    func updateFailedSseAuth(error: Error) {
        sseAuthResult = DataResult.failure(error: error as NSError)
    }
}
