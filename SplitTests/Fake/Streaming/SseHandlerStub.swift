//
//  SseHandlerStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 02/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class SseHandlerStub: SseHandler {
    var errorExpectation: XCTestExpectation?
    var messageExpectation: XCTestExpectation?
    var isConfirmed = true

    var errorReportedCalled = false
    var errorRetryableReported = false
    func reportError(isRetryable: Bool) {
        errorReportedCalled = true
        errorRetryableReported = isRetryable
        if let exp = errorExpectation {
            exp.fulfill()
        }
    }

    var handleIncomingCalled = false
    func handleIncomingMessage(message: [String: String]) {
        handleIncomingCalled = true
        print("Stub SSE Handler message arrived: \(message)")
        if let exp = messageExpectation {
            exp.fulfill()
        }
    }

    func isConnectionConfirmed(message: [String: String]) -> Bool {
        return isConfirmed
    }
}
