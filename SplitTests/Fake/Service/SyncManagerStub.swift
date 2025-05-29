//
//  SyncManagerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 21-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class SyncManagerStub: SyncManager {
    var setupUserConsentExp: XCTestExpectation?

    var startCalled = false
    func start() {
        startCalled = true
    }

    var resetStreamingCalled = false
    func resetStreaming() {
        resetStreamingCalled = true
    }

    var pauseCalled = false
    func pause() {
        pauseCalled = true
    }

    var resumeCalled = false
    func resume() {
        resetStreamingCalled = true
    }

    var stopCalled = false
    func stop() {
        stopCalled = true
    }

    var setupUserConsentCalled = false
    var setupUserConsentValue: UserConsent?
    func setupUserConsent(for status: UserConsent) {
        setupUserConsentCalled = true
        setupUserConsentValue = status
        if let exp = setupUserConsentExp {
            exp.fulfill()
        }
    }
}
