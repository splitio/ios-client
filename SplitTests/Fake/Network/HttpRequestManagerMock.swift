//
//  HttpRequestManagerMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 07/07/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class HttpRequestManagerMock: HttpRequestManager {
    // Function counters
    var addRequestCallCount = 0
    var appendDataCallCount = 0
    var setResponseCodeCallCount = 0
    var notifyErrorCallCount = 0
    var request: HttpRequest!

    var setResponseCodeDummyValue = false

    func addRequest(_ request: HttpRequest) {
        addRequestCallCount += 1
        self.request = request
    }

    func append(data: Data, to taskIdentifier: Int) {
        appendDataCallCount += 1

        if let r = request as? HttpDataRequest {
            r.notifyIncomingData(data)
        } else if let r = request as? HttpStreamRequest {
            r.notifyIncomingData(data)
        }
    }

    func complete(taskIdentifier: Int, error: HttpError?) {
        notifyErrorCallCount += 1
        request.complete(error: error)
    }

    func set(responseCode: Int, to taskIdentifier: Int) -> Bool {
        setResponseCodeCallCount += 1
        request.setResponse(code: responseCode)
        request.complete(error: nil)
        return setResponseCodeDummyValue
    }

    func destroy() {
        addRequestCallCount = 0
        appendDataCallCount = 0
        setResponseCodeCallCount = 0
        notifyErrorCallCount = 0
    }
}
