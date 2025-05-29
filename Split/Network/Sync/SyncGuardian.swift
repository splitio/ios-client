//
//  SyncGuardian.swift
//  Split
//
//  Created by Javier Avrudsky on 01/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

protocol SyncGuardian {
    func setMaxSyncPeriod(_ newPeriod: Int64)
    func updateLastSyncTimestamp()
    func mustSync() -> Bool
}

class DefaultSyncGuardian: SyncGuardian {
    typealias TimestampProvider = () -> Int64
    private let defaultMaxSyncPeriod: Int64
    private var maxSyncPeriod: Int64
    private var lastSyncTimestamp: Int64?
    private var newTimestamp: () -> Int64
    private var splitConfig: SplitClientConfig
    private let queue = DispatchQueue(label: "split-sync-guardian", target: .global())

    /// Parameter: maxSyncPeriod in millis
    init(
        maxSyncPeriod: Int64,
        splitConfig: SplitClientConfig,
        timestampProvider: TimestampProvider? = nil) {
        self.defaultMaxSyncPeriod = maxSyncPeriod
        self.maxSyncPeriod = maxSyncPeriod
        self.splitConfig = splitConfig
        self.newTimestamp = timestampProvider ?? { Date().unixTimestampInMiliseconds() }
    }

    func updateLastSyncTimestamp() {
        queue.sync {
            lastSyncTimestamp = newTimestamp()
        }
    }

    func mustSync() -> Bool {
        queue.sync {
            if splitConfig.syncEnabled, splitConfig.streamingEnabled,
               newTimestamp() - (lastSyncTimestamp ?? 0) >= maxSyncPeriod {
                return true
            }
            return false
        }
    }

    /// Parameter: newPeriod in millis
    func setMaxSyncPeriod(_ newPeriod: Int64) {
        queue.sync {
            if newPeriod >= defaultMaxSyncPeriod {
                maxSyncPeriod = newPeriod
            } else {
                maxSyncPeriod = defaultMaxSyncPeriod
            }
        }
    }
}
