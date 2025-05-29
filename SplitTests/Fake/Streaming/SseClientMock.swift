//
//  SseClientStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 17/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class SseClientMock: SseClient {
    var isConnectionOpened: Bool = true

    private var resultIndex = 0
    var connectCalled = false
    var disconnectCalled = false
    var token: String?
    var channels: [String]?
    var successHandler: CompletionHandler?
    var results: [Bool]?
    var closeExp: XCTestExpectation?
    var disconnectDelay: Double?

    init(connected: Bool = true) {
        self.isConnectionOpened = connected
    }

    func connect(token: String, channels: [String], completion: @escaping CompletionHandler) {
        successHandler = completion
        self.token = token
        self.channels = channels
        let result = results![resultIndex]
        if resultIndex < results!.count - 1 {
            resultIndex += 1
        }
        connectCalled = true
        if result {
            completion(true)
        }
    }

    func disconnect() {
        disconnectCalled = true
        if let exp = closeExp {
            exp.fulfill()
        }
        if let delay = disconnectDelay {
            Thread.sleep(forTimeInterval: delay)
        }
    }
}
