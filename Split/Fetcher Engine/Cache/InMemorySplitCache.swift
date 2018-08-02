//
//  InMemorySplitCache.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

@objc public final class InMemorySplitCache: NSObject, SplitCacheProtocol {
    private let queueName = "split.inmemcache-queue"
    private var queue: DispatchQueue
    private var splits: [String: Split]
    private var changeNumber: Int64
    
    public init(splits: [String: Split] = [:], changeNumber: Int64 = -1) {
        self.queue = DispatchQueue(label: queueName, attributes: .concurrent)
        self.splits = splits
        self.changeNumber = changeNumber
    }
    
    public func addSplit(splitName: String, split: Split) -> Bool {
        queue.async(flags: .barrier) {
            self.splits[splitName] = split
        }
        return true
    }
    
    public func removeSplit(splitName: String) -> Bool {
        queue.async(flags: .barrier) {
            self.splits.removeValue(forKey: splitName)
        }
        return true
    }
    
    public func setChangeNumber(_ changeNumber: Int64) -> Bool {
        queue.async(flags: .barrier) {
            self.changeNumber = changeNumber
        }
        return true
    }
    
    public func getChangeNumber() -> Int64 {
        var number: Int64 = -1
        queue.sync {
            number = self.changeNumber
        }
        return number
    }
    
    public func getSplit(splitName: String) -> Split? {
        var split: Split? = nil
        queue.sync {
            split = self.splits[splitName]
        }
        return split
    }
    
    public func getAllSplits() -> [Split] {
        var splits = [Split]()
        queue.sync {
            splits = Array(self.splits.values)
        }
        return splits
    }
    
    public func clear() {
    }
}
