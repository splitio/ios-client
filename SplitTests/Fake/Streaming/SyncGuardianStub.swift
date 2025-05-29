//
//  SyncGuardianStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 06/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
@testable import Split

class SyncGuardianStub: SyncGuardian {
    var maxSyncPeriod: Int64 = 0
    func setMaxSyncPeriod(_ newPeriod: Int64) {
        maxSyncPeriod = newPeriod
    }

    var updateLastSyncTimestampCalled = false
    func updateLastSyncTimestamp() {
        updateLastSyncTimestampCalled = true
    }

    var mustSyncCalled = false
    var mustSyncValue = false
    func mustSync() -> Bool {
        mustSyncCalled = true
        return mustSyncValue
    }
}
