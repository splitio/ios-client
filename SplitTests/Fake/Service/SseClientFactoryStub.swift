//
//  SseClientFactoryStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 04-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class SseClientFactoryStub: SseClientFactory, @unchecked Sendable {


    var clients = [SseClientMock]()
    var clientIndex = 0
    func create() -> SseClient {
        let client = clients[clientIndex]
        clientIndex+=1
        return client
    }
}
