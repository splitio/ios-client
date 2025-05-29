//
//  ClientManagerMock.swift
//  ests
//
//  Created by Javier Avrudsky on 10/04/2024.
//  Copyright © 2024  All rights reserved.
//

import Foundation
@testable import Split

class ClientManagerMock: SplitClientManager {
    var splitFactory: SplitFactory? = SplitFactoryStub(apiKey: "apiKey")

    var defaultClient: SplitClient?
    var clients = [Key: SplitClient]()

    func get(forKey key: Key) -> SplitClient {
        return clients[key] ?? SplitClientStub()
    }

    var flushCalled = false
    func flush() {
        flushCalled = true
    }

    var destroyCalled = [Key: Bool]()
    func destroy(forKey key: Key) {
        destroyCalled[key] = true
    }
}
