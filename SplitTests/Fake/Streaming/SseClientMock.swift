//
//  SseClientStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 17/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class SseClientMock: SseClient {
    var isConnectionOpened: Bool = true


    private var resultIndex = 0
    var connectCalled = false
    var disconnectCalled = false
    var token: String?
    var channels: [String]?
    var successHandler: CompletionHandler?
    var results: [Bool]?

    func connect(token: String, channels: [String], completion: @escaping CompletionHandler) {
        self.successHandler = completion
        self.token = token
        self.channels = channels
        let result = results![resultIndex]
        if resultIndex < results!.count - 1 {
            resultIndex+=1
        }
        connectCalled = true
        if result {
            completion(true)
        }
    }

    func disconnect() {
        disconnectCalled = true
//        fireOnDisconnect()
    }
}
