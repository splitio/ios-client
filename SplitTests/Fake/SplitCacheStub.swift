//
//  StubSplitCache.swift
//  SplitTests
//
//  Created by Javier on 04/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SplitCacheStub: SplitCacheProtocol {
    
    var clearExpectation: XCTestExpectation?
    var onSplitsUpdatedHandler: (([Split]) -> Void)? = nil
    private var changeNumber: Int64
    private var splits: [String:Split]
    var timestamp = 0
    private var queryString = ""

    var killedSplit: Split?
    var killExpectation: XCTestExpectation?

    var clearCallCount = 0
    init(splits: [Split], changeNumber: Int64, queryString: String = "") {
        self.changeNumber = changeNumber
        self.queryString = queryString
        self.splits = [String:Split]()
        for split in splits {
            self.splits[split.name!.lowercased()] = split
        }
    }

    func addSplit(splitName: String, split: Split) {
        splits[splitName.lowercased()] = split
    }

    func deleteSplit(name: String) {
        splits.removeValue(forKey: name.lowercased())
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
        clearCallCount+=1
        splits.removeAll()
        changeNumber = -1
        if let exp = clearExpectation {
            exp.fulfill()
        }
    }

    func exists(trafficType: String) -> Bool {
        return true
    }
    
    func exists(lowercasedTrafficType: String) -> Bool {
        return true
    }

    func getTimestamp() -> Int {
        return timestamp
    }

    func setTimestamp(_ timestamp: Int) {
        self.timestamp = timestamp
    }

    func kill(splitName: String, defaultTreatment: String, changeNumber: Int64) {
        killedSplit = Split()
        killedSplit?.name = splitName
        killedSplit?.defaultTreatment = defaultTreatment
        killedSplit?.changeNumber = changeNumber

        if let exp = killExpectation {
            exp.fulfill()
        }
    }

    func setQueryString(_ queryString: String) {
        self.queryString = queryString
    }

    func getQueryString() -> String {
        return queryString
    }
}
