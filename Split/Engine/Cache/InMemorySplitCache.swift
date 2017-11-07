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
    
    public func addSplit(splitName: String, split: Split) {
        self.splits[splitName] = split
    }
    
    public func removeSplit(splitName: String) {
        self.splits.removeValue(forKey: splitName)
    }
    
    public func setChangeNumber(_ changeNumber: Int64) {
        self.changeNumber = changeNumber
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
