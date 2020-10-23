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

    private var resultIndex = 0
    var connectCalled = false
    var disconnectCalled = false
    var token: String?
    var channels: [String]?
    var successHandler: SuccessHandler?
    var results: [Bool]?

    func connect(token: String, channels: [String], success: @escaping SuccessHandler) {
        self.successHandler = success
        self.token = token
        self.channels = channels
        let result = results![resultIndex]
        if resultIndex < results!.count - 1 {
            resultIndex+=1
        }
        connectCalled = true
        if result {
            success()
        }
    }

    func disconnect() {
        disconnectCalled = true
//        fireOnDisconnect()
    }
}
