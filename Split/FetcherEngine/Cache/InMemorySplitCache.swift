//
//  InMemorySplitCache.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

class InMemorySplitCache: NSObject, SplitCacheProtocol {

    private let queueName = "split.inmemcache-queue.splits"
    private var queue: DispatchQueue
    private var splits: [String: Split]
    private var changeNumber: Int64

    init(splits: [String: Split] = [:], changeNumber: Int64 = -1) {
        self.queue = DispatchQueue(label: queueName, attributes: .concurrent)
        self.splits = splits
        self.changeNumber = changeNumber
    }

    func addSplit(splitName: String, split: Split) {
        queue.async(flags: .barrier) {
            self.splits[splitName] = split
        }
    }

    func removeSplit(splitName: String) {
        queue.async(flags: .barrier) {
            self.splits.removeValue(forKey: splitName)
        }
    }

    func setChangeNumber(_ changeNumber: Int64) {
        queue.async(flags: .barrier) {
            self.changeNumber = changeNumber
        }
    }

    func getChangeNumber() -> Int64 {
        var number: Int64 = -1
        queue.sync {
            number = self.changeNumber
        }
        return number
    }

    func getSplit(splitName: String) -> Split? {
        var split: Split? = nil
        queue.sync {
            split = self.splits[splitName]
        }
        return split
    }

    func getSplits() -> [String: Split] {
        var splits: [String: Split]!
        queue.sync {
            splits = self.splits
        }
        return splits
    }

    func getAllSplits() -> [Split] {
        var splits = [Split]()
        queue.sync {
            splits = Array(self.splits.values)
        }
        return splits
    }

    public func clear() {
        queue.async(flags: .barrier) {
            self.splits.removeAll()
        }
    }
}
