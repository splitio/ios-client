//
//  SseHandlerStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 02/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class SseHandlerStub: SseHandler {
    var handleIncomingCalled = false
    func handleIncomingMessage(message: [String : String]) {
        handleIncomingCalled = true
    }
}
