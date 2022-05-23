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
    private let uniqueKeyRecorder: HttpUniqueKeysRecorder
    private let uniqueKeyPerPush: Int
    private let accumulator: 

    init(uniqueKeyStorage: PersistentUniqueKeysStorage,
         uniqueKeyRecorder: HttpUniqueKeysRecorder,
         uniqueKeyPerPush: Int,
         uniqueKeySyncHelper: UniqueKeyRecorderSyncHelper? = nil) {

        self.uniqueKeyStorage = uniqueKeyStorage
        self.uniqueKeyRecorder = uniqueKeyRecorder
        self.uniqueKeyPerPush = uniqueKeyPerPush
        self.uniqueKeySyncHelper = uniqueKeySyncHelper

    }

    func flush() {
        var rowCount = 0
        var failedUniqueKeys = [UniqueKey]()
        repeat {
            let keys = uniqueKeyStorage.pop(count: uniqueKeyPerPush)
            rowCount = keys.count
            if rowCount > 0 {
                Logger.d("Sending uniqueKey")
                do {
                    _ = try uniqueKeyRecorder.execute(group(keys: keys))
                    // Removing sent uniqueKey
                    uniqueKeyStorage.delete(keys)
                    Logger.d("Impression posted successfully")
                } catch let error {
                    Logger.e("Impression error: \(String(describing: error))")
                    failedUniqueKeys.append(contentsOf: keys)
                }
            }
        } while rowCount == uniqueKeyPerPush
        // Activate non sent uniqueKey to retry in next iteration
        uniqueKeyStorage.setActiveAndUpdateSendCount(failedUniqueKeys.compactMap { $0.storageId })
        if let syncHelper = uniqueKeySyncHelper {
            syncHelper.updateAccumulator(count: failedUniqueKeys.count,
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
