//
//  ImpressionsStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 02-Dec-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class ImpressionsStorageStub: ImpressionsStorage, @unchecked Sendable {

    var enablePersistenceCalled = false
    var enablePersistenceValue: Bool?
    var impressions = [KeyImpression]()

    func enablePersistence(_ enable: Bool) {
        enablePersistenceCalled = true
        enablePersistenceValue = enable
    }

    var pushCalled = false
    func push(_ impression: KeyImpression) {
        impressions.append(impression)
    }

    var clearInMemoryCalled = false
    func clearInMemory() {
        clearInMemoryCalled = true
        impressions.removeAll()
    }
}
