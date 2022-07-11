//
//  UniqueKeysRecorderWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class UniqueKeysRecorderWorker: RecorderWorker {

    private let uniqueKeyStorage: PersistentUniqueKeysStorage
    private let uniqueKeysRecorder: HttpUniqueKeysRecorder
    private let flushChecker: RecorderFlushChecker?
    private let rowsPerPush = ServiceConstants.uniqueKeyBulkSize

    init(uniqueKeyStorage: PersistentUniqueKeysStorage,
         uniqueKeysRecorder: HttpUniqueKeysRecorder,
         flushChecker: RecorderFlushChecker? = nil) {

        self.uniqueKeyStorage = uniqueKeyStorage
        self.uniqueKeysRecorder = uniqueKeysRecorder
        self.flushChecker = flushChecker
    }

    func flush() {
        var rowCount = 0
        var failedUniqueKeys = [UniqueKey]()
        repeat {
            let keys = uniqueKeyStorage.pop(count: rowsPerPush)
            rowCount = keys.count
            if rowCount > 0 {
                Logger.d("Sending unique keys")
                do {
                    _ = try uniqueKeysRecorder.execute(group(keys: keys))
                    // Removing sent uniqueKey
                    uniqueKeyStorage.delete(keys)
                    Logger.i("Unique keys posted successfully")
                } catch let error {
                    Logger.e("Unique keys error: \(String(describing: error))")
                    failedUniqueKeys.append(contentsOf: keys)
                }
            }
        } while rowCount == rowsPerPush
        // Activate non sent uniqueKey to retry in next iteration
        uniqueKeyStorage.setActiveAndUpdateSendCount(failedUniqueKeys.compactMap { $0.storageId })
        if let flushChecker = self.flushChecker {
            flushChecker.update(count: failedUniqueKeys.count,
                                bytes: failedUniqueKeys.count *
                                ServiceConstants.estimatedImpressionSizeInBytes)
        }

    }

    private func group(keys: [UniqueKey]) -> UniqueKeys {
        var grouped = [String: Set<String>]()
        keys.forEach { uniqueKey in
            let userKey = uniqueKey.userKey
            grouped[userKey] = uniqueKey.features.union(grouped[userKey] ?? Set<String>())

        }
        return UniqueKeys(keys: grouped.map { userKey, features in
            return UniqueKey(userKey: userKey, features: features)
        })
    }
}
