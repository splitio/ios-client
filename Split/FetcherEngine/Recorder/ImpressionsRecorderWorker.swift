//
//  ImpressionsRecorderWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class ImpressionsRecorderWorker: RecorderWorker, @unchecked Sendable {

    private let persistentImpressionsStorage: PersistentImpressionsStorage
    private let impressionsRecorder: HttpImpressionsRecorder
    private let impressionsPerPush: Int
    private let impressionsSyncHelper: ImpressionsRecorderSyncHelper?

    init(persistentImpressionsStorage: PersistentImpressionsStorage,
         impressionsRecorder: HttpImpressionsRecorder,
         impressionsPerPush: Int,
         impressionsSyncHelper: ImpressionsRecorderSyncHelper? = nil) {

        self.persistentImpressionsStorage = persistentImpressionsStorage
        self.impressionsRecorder = impressionsRecorder
        self.impressionsPerPush = impressionsPerPush
        self.impressionsSyncHelper = impressionsSyncHelper

    }

    func flush() {
        var rowCount = 0
        var failedCount = 0
        repeat {
            let impressions = persistentImpressionsStorage.pop(count: impressionsPerPush)
            rowCount = impressions.count
            if rowCount > 0 {
                Logger.d("Sending impressions")
                do {
                    _ = try impressionsRecorder.execute(group(impressions: impressions))
                    // Removing sent impressions
                    persistentImpressionsStorage.delete(impressions)
                    Logger.i("Impressions posted successfully")
                } catch let error {
                    Logger.e("Impression error: \(String(describing: error))")
                    // Impressions remain in DB for retry on next flush cycle
                    failedCount = rowCount
                    break
                }
            }
        } while rowCount == impressionsPerPush
        if let syncHelper = impressionsSyncHelper {
            syncHelper.updateAccumulator(count: failedCount,
                                         bytes: failedCount *
                                            ServiceConstants.estimatedImpressionSizeInBytes)
        }
    }

    private func group(impressions: [KeyImpression]) -> [ImpressionsTest] {
        return Dictionary(grouping: impressions, by: { $0.featureName ?? "" })
            .compactMap { return ImpressionsTest(testName: $0.key, keyImpressions: $0.value) }
    }
}
