//
//  InMemorySplitCache.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

@objc public final class InMemorySplitCache: NSObject, SplitCacheProtocol {
    
    private let splits: NSMutableDictionary
    private var changeNumber: Int64
    
    public init(splits: NSMutableDictionary = NSMutableDictionary(), changeNumber: Int64 = -1) {
        self.splits = splits
        self.changeNumber = changeNumber
    }
    
    public func addSplit(splitName: String, split: SplitBase) {
        self.splits.setValue(split, forKey: splitName)
    }
    
    public func removeSplit(splitName: String) {
        self.splits.removeObject(forKey: splitName)
    }
    
    public func setChangeNumber(_ changeNumber: Int64) {
        self.changeNumber = changeNumber
    }
    
    public func getChangeNumber() -> Int64 {
        return self.changeNumber
    }
    
    public func getSplit(splitName: String) -> SplitBase? {
        return self.splits.value(forKey: splitName) as? SplitBase
    }
    
    public func getAllSplits() -> [SplitBase] {
        return self.splits.allValues.map { return $0 as! SplitBase }
    }
    
    public func clear() {
        return self.splits.removeAllObjects()
    }
    
}
