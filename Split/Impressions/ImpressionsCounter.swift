//
//  ImpressionsCounter.swift
//  Split
//
//  Created by Javier Avrudsky on 22/06/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

class ImpressionsCounter {
    struct Key: Hashable {
        let featureName: String
        let timeframe: Int64
    }
    private let queue: DispatchQueue = DispatchQueue(label: "split-impressions-counter", attributes: .concurrent)
    private var counts = [Key: Int]()

    func inc(featureName: String, timeframe: Int64, amount: Int) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let truncatedTimeframe = Date.truncateTimeframe(millis: timeframe)
            let key = Key(featureName: featureName, timeframe: truncatedTimeframe)
            self.counts[key] = (self.counts[key] ?? 0) + amount
        }
    }

    func popAll() -> [ImpressionsCountPerFeature] {
        var poppedCounts = [ImpressionsCountPerFeature]()
        queue.sync {
            poppedCounts.append(contentsOf: counts.compactMap { ImpressionsCountPerFeature(feature: $0.key.featureName,
                                                                                           timeframe: $0.key.timeframe,
                                                                                           count: $0.value)
            })
            counts.removeAll()
        }
        return poppedCounts
    }

    func isEmpty() -> Bool {
        queue.sync {
            return counts.isEmpty
        }
    }
}
