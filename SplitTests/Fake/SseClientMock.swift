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
    var results: [SseConnectionResult]?
    private var resultIndex = 0
    var token: String?
    var channels: [String]?

    var onOpenHandler: EventHandler?

    var onErrorHandler: ErrorHandler?

    var onDisconnectHandler: EventHandler?

    var onMessageHandler: MessageHandler?

    func connect(token: String, channels: [String]) -> SseConnectionResult {
        self.token = token
        self.channels = channels
        let result = results![resultIndex]
        if resultIndex < results!.count - 1 {
            resultIndex+=1
        }
        return result
    }
}
