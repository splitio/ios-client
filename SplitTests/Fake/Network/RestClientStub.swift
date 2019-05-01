//
//  RestClientStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 23/04/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

protocol RestClientTest {
    func update(segments: [String]?)
    func update(change: SplitChange?)
}

class RestClientStub {
    private var segments: [String]?
    private var splitChange: SplitChange?
}

extension RestClientStub: RestClientProtocol {
    func isServerAvailable(_ url: URL) -> Bool { return true }
    func isServerAvailable(path url: String) -> Bool { return true }
    func isEventsServerAvailable() -> Bool { return true }
    func isSdkServerAvailable() -> Bool { return true }
}

extension RestClientStub: RestClientSplitChanges {
    func getSplitChanges(since: Int64, completion: @escaping (DataResult<SplitChange>) -> Void) {
        completion(DataResult.Success(value: splitChange))
    }
}

extension RestClientStub: RestClientMySegments {
    func getMySegments(user: String, completion: @escaping (DataResult<[String]>) -> Void) {
        completion(DataResult.Success(value: segments))
    }
}

extension RestClientStub: RestClientTest {
    func update(segments: [String]?) {
        self.segments = segments
    }
    
    func update(change: SplitChange?) {
        self.splitChange = change
    }
}
