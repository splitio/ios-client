//
//  ImpressionsCountRecorderWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 23/06/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

class ImpressionsCountRecorderWorker: RecorderWorker {

    private let countsStorage: PersistentImpressionsCountStorage
    private let countsRecorder: HttpImpressionsCountRecorder
    private let kPopCount = ServiceConstants.defaultImpressionCountRowsPop

    init(countsStorage: PersistentImpressionsCountStorage,
         countsRecorder: HttpImpressionsCountRecorder) {
        self.countsStorage = countsStorage
        self.countsRecorder = countsRecorder
    }

    func flush() {
        var rowCount = 0
        var failedCounts = [ImpressionsCountPerFeature]()
        repeat {
            let counts = countsStorage.pop(count: kPopCount)
            rowCount = counts.count
            if rowCount > 0 {
                Logger.d("Sending impressions count")
                do {
                    _ = try countsRecorder.execute(ImpressionsCount(perFeature: counts))
                    // Removing sent impressions
                    countsStorage.delete(counts)
                    Logger.i("Impressions counts posted successfully")
                } catch let error {
                    Logger.e("Impressions counts error: \(String(describing: error))")
                    failedCounts.append(contentsOf: counts)
                }
            }
        } while rowCount == kPopCount
        // Activate non sent counts to retry in next iteration
        countsStorage.setActive(failedCounts)
    }
}
