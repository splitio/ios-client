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
    var token: String?
    var channels: [String]?

    var onOpenHandler: EventHandler?

    var onErrorHandler: ErrorHandler?

    var onDisconnectHandler: EventHandler?

    var onMessageHandler: MessageHandler?

    func connect(token: String, channels: [String]) {
        self.token = token
        self.channels = channels
    }
}
