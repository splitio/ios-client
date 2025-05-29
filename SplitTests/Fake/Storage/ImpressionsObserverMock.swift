//
//  ImpressionsObserverMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 24/05/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split

class ImpressionsObserverMock: ImpressionsObserver {
    var testAndSetCalled = false
    func testAndSet(impression: KeyImpression) -> Int64? {
        testAndSetCalled = true
        return nil
    }

    var clearCalled = false
    func clear() {
        clearCalled = true
    }

    var saveCalled = false
    func saveHashes() {
        saveCalled = true
    }
}
