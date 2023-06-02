//
//  SyncGuardian.swift
//  Split
//
//  Created by Javier Avrudsky on 01/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

protocol SyncGuardian {
    var maxSyncPeriod: Int64 { get set }
    func updateLastSyncTimestamp()
    func mustSync() -> Bool
}

class DefaultSyncGuardian: SyncGuardian {
    typealias TimestampProvider = () -> Int64
    var maxSyncPeriod: Int64
    private var lastSyncTimestamp: Int64?
    private var newTimestamp: () -> Int64

    init(maxSyncPeriod: Int64, timestampProvider: TimestampProvider? = nil) {
        self.maxSyncPeriod = maxSyncPeriod
        self.newTimestamp = timestampProvider ?? { return Date().unixTimestampInMiliseconds() }
    }

    func updateLastSyncTimestamp() {
        lastSyncTimestamp = newTimestamp()
    }

    func mustSync() -> Bool {
        if newTimestamp() - (lastSyncTimestamp ?? 0) >= maxSyncPeriod {
            return true
        }
        return false
    }
}
