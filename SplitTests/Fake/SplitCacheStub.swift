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

    var onSplitsUpdatedHandler: (([Split]) -> Void)? = nil
    private var changeNumber: Int64
    private var splits: [String:Split]
    init(splits: [Split], changeNumber: Int64) {
        self.changeNumber = changeNumber
        self.splits = [String:Split]()
        for split in splits {
            self.splits[split.name!.lowercased()] = split
        }
    }
    
    func addSplit(splitName: String, split: Split) {
        splits[splitName.lowercased()] = split
    }
    
    func removeSplit(splitName: String) {
        splits.removeValue(forKey: splitName.lowercased())
    }
    
    func setChangeNumber(_ changeNumber: Int64) {
        self.changeNumber = changeNumber
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
    
    func getSplits() -> [String : Split] {
        return splits
    }
    
    func clear() {
    }
    
}
