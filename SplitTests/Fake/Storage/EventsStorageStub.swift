//
//  EventsStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 02-Dec-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class EventsStorageStub: EventsStorage {
    var enablePersistenceCalled = false
    var enablePersistenceValue: Bool?

    func enablePersistence(_ enable: Bool) {
        enablePersistenceCalled = true
        enablePersistenceValue = enable
    }

    var pushCalled = false
    func push(_ event: EventDTO) {
        pushCalled = true
    }

    var clearInMemoryCalled = false
    func clearInMemory() {
        clearInMemoryCalled = true
    }
}
