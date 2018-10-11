//
//  StubSplitCache.swift
//  SplitTests
//
//  Created by Javier on 04/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitCacheStub: SplitCacheProtocol {
    
    private let kClassName = String(describing: SplitCache.self)
    private var changeNumber: Int64
    private var splits: [String:Split]
    init(splits: [Split], changeNumber: Int64) {
        self.changeNumber = changeNumber
        self.splits = [String:Split]()
        for split in splits {
            self.splits[split.name!.lowercased()] = split
        }
    }
    
    @discardableResult
    func addSplit(splitName: String, split: Split) -> Bool {
        splits[splitName.lowercased()] = split
        return true
    }
    
    @discardableResult
    func removeSplit(splitName: String) -> Bool {
        splits.removeValue(forKey: splitName.lowercased())
        return true
    }
    
    @discardableResult
    func setChangeNumber(_ changeNumber: Int64) -> Bool {
        self.changeNumber = changeNumber
        return true
    }
    
    private func getChangeNumberId() -> String {
        return ""
    }
    
    public func getChangeNumber() -> Int64 {
        return changeNumber
    }
    
    func getSplit(splitName: String) -> Split? {
        return splits[splitName.lowercased()]
    }
    
    func getAllSplits() -> [Split] {
        return Array(splits.values)
    }
    
    func clear() {
    }
    
}
