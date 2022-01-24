//
//  LatencyBucketHandler.swift
//  Split
//
//  Created by Javier on 28/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

/**
 * Tracks latencies per bucket of time.
 * Each bucket represent a latency greater than the one before
 * and each number within each bucket is a number of calls in the range.
 * <p/>
 * (1)  1.00
 * (2)  1.50
 * (3)  2.25
 * (4)  3.38
 * (5)  5.06
 * (6)  7.59
 * (7)  11.39
 * (8)  17.09
 * (9)  25.63
 * (10) 38.44
 * (11) 57.67
 * (12) 86.50
 * (13) 129.75
 * (14) 194.62
 * (15) 291.93
 * (16) 437.89
 * (17) 656.84
 * (18) 985.26
 * (19) 1,477.89
 * (20) 2,216.84
 * (21) 3,325.26
 * (22) 4,987.89
 * (23) 7,481.83
 */
class LatencyCounter {

    // Removed first bucket (1000) for practical
    // reasons
    // Array is in microseconds
    private let kLatencyBuckets: [Int64] = [
        1500, 2250, 3375, 5063,
        7594, 11391, 17086, 25629, 38443,
        57665, 86498, 129746, 194620, 291929,
        437894, 656841, 985261, 1477892, 2216838,
        3325257, 4987885, 7481828
    ]
    private static let kMaxBucketIndex = 22
    private let kMaxLatency: Int64 = 7481828
    private var counters = [Int]()

    var allCounters: [Int] {
        return counters
    }

    init() {
        counters = LatencyCounter.emptyCounters()
    }

    func resetCounters() {
        counters = LatencyCounter.emptyCounters()
    }

    func addLatency(microseconds time: Int64) {
        counters[findBucketIndex(for: time)] += 1
    }

    func count(for index: Int) -> Int {
        if index < 0 || index > LatencyCounter.kMaxBucketIndex { return -1 }
        return counters[index]
    }

    private func findBucketIndex(for latency: Int64) -> Int {

        // Although Binary Search is O(log n) and Linear Search is O(n)
        // we're using Linear Search because is faster in small arrays
        if let index = kLatencyBuckets.firstIndex(where: { latency < $0 }) {
            return index
        }
        return LatencyCounter.kMaxBucketIndex
    }

    private static func emptyCounters() -> [Int] {
        return Array(repeating: 0, count: kMaxBucketIndex + 1)
    }
}
