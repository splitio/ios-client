//
//  RestClientStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 23/04/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

protocol RestClientTest {
    func update(segments: [String]?)
    func update(change: SplitChange?)
    func update(changes: [SplitChange])
    func update(response: SseAuthenticationResponse?)
    func updateFailedSseAuth(error: Error)
}

class RestClientStub: SplitApiRestClient {
    private var sseAuthResult: DataResult<SseAuthenticationResponse>?
    private var segments: [String]?
    private var splitChanges: [SplitChange] = []
    private var sendTrackEventsCount = 0
    private var sendImpressionsCount = 0
    var isServerAvailable = true
    private var splitChangeHitIndex = 0
    
    func getSendTrackEventsCount() -> Int {
        return sendTrackEventsCount;
    }
    
    func getSendImpressionsCount() -> Int {
        return sendImpressionsCount;
    }
}

extension RestClientStub: RestClient {
    func isServerAvailable(_ url: URL) -> Bool { return isServerAvailable }
    func isServerAvailable(path url: String) -> Bool { return isServerAvailable }
    func isEventsServerAvailable() -> Bool { return isServerAvailable }
    func isSdkServerAvailable() -> Bool { return isServerAvailable }
}

extension RestClientStub: RestClientSplitChanges {
    func getSplitChanges(since: Int64, completion: @escaping (DataResult<SplitChange>) -> Void) {
        if splitChanges.count == 0 {
            completion(DataResult.success(value: nil))
            return
        }
        let hit = splitChangeHitIndex
        splitChangeHitIndex += 1
        if hit <= splitChanges.count - 1 {
            completion(DataResult.success(value: splitChanges[hit]))
            return
        }
        completion(DataResult.success(value: splitChanges[splitChanges.count - 1]))
    }
}

extension RestClientStub: RestClientMySegments {
    func getMySegments(user: String, completion: @escaping (DataResult<[String]>) -> Void) {
        completion(DataResult.success(value: segments))
    }
}

extension RestClientStub: RestClientTrackEvents {
    func sendTrackEvents(events: [EventDTO], completion: @escaping (DataResult<EmptyValue>) -> Void) {
        sendTrackEventsCount+=1
        completion(DataResult.success(value: nil))
    }
}

extension RestClientStub: RestClientImpressions {
    func sendImpressions(impressions: [ImpressionsTest], completion: @escaping (DataResult<EmptyValue>) -> Void) {
        sendImpressionsCount+=1
        completion(DataResult.success(value: nil))
    }
}

extension RestClientStub: RestClientSseAuthenticator {
    func authenticate(userKey: String, completion: @escaping (DataResult<SseAuthenticationResponse>) -> Void) {
        completion(self.sseAuthResult!)
    }
}

extension RestClientStub: MetricsRestClient {
    func sendTimeMetrics(_ times: [TimeMetric], completion: @escaping (DataResult<EmptyValue>) -> Void) {
    }

    func sendCounterMetrics(_ counters: [CounterMetric], completion: @escaping (DataResult<EmptyValue>) -> Void) {
    }

    func sendGaugeMetrics(_ gauge: MetricGauge, completion: @escaping (DataResult<EmptyValue>) -> Void) {
    }
}

extension RestClientStub: RestClientTest {
    func update(changes: [SplitChange]) {
        self.splitChanges = changes
    }
    
    func update(segments: [String]?) {
        self.segments = segments
    }

    func update(change: SplitChange?) {
        if let change = change {
            self.splitChanges.append(change)
            
        } else {
            self.splitChanges.removeAll()
        }
    }

    func update(response: SseAuthenticationResponse?) {
        self.sseAuthResult = DataResult.success(value: response)
    }

    func updateFailedSseAuth(error: Error) {
        self.sseAuthResult = DataResult.failure(error: error as NSError)
    }
}
