//
//  TelemetrySynchronizerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 29-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class TelemetrySynchronizerStub: TelemetrySynchronizer {
    var synchronizeConfigCalled = false
    var synchronizeStatsCalled = false
    var startCalled = false
    var pauseCalled = false
    var resumeCalled = false
    var destroyCalled = false

    func synchronizeConfig() {
        synchronizeConfigCalled = true
    }

    func synchronizeStats() {
        synchronizeStatsCalled = true
    }

    func start() {
        startCalled = true
    }

    func pause() {
        pauseCalled = true
    }

    func resume() {
        resumeCalled = true
    }

    func destroy() {
        destroyCalled = true
    }
}
