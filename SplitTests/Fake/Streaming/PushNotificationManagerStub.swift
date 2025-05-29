//
//  PushNotificationManagerStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 09/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class PushNotificationManagerStub: PushNotificationManager {
    var jwtParser: JwtTokenParser = DefaultJwtTokenParser()
    var startCalled = false
    var stopCalled = false
    var pauseCalled = false
    var resumeCalled = false
    var disconnectCalled = false

    func start() {
        startCalled = true
    }

    func stop() {
        stopCalled = true
    }

    func pause() {
        pauseCalled = true
    }

    func resume() {
        resumeCalled = true
    }

    func disconnect() {
        disconnectCalled = true
    }

    var resetCalled = false
    func reset() {
        resetCalled = true
    }
}
