//
//  InMemorySplitCache.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

@objc public final class InMemorySplitCache: NSObject, SplitCacheProtocol {
    
    private var splits: [String: Split]
    private var changeNumber: Int64
    
    public init(splits: [String: Split] = [:], changeNumber: Int64 = -1) {
        self.splits = splits
        self.changeNumber = changeNumber
    }
    
    public func addSplit(splitName: String, split: Split) -> Bool {
        self.splits[splitName] = split
        return true
    }
    
    public func removeSplit(splitName: String) -> Bool {
        self.splits.removeValue(forKey: splitName)
        return true
    }
    
    public func setChangeNumber(_ changeNumber: Int64) -> Bool {
        self.changeNumber = changeNumber
        return true
    }
    
    public func getChangeNumber() -> Int64 {
        return self.changeNumber
    }
    
    public func getSplit(splitName: String) -> Split? {
        return self.splits[splitName]
    }
    
    public func getAllSplits() -> [Split] {
        return Array(self.splits.values)
    }
    
    public func clear() {
        return self.splits.removeAll()
    }
    
}
