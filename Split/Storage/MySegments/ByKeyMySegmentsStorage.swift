//
//  ByKeyMySegmentsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 03-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol ByKeyMySegmentsStorage {
    var changeNumber: Int64 { get }
    func loadLocal()
    func getAll() -> Set<String>
    func set(_ change: SegmentChange)
    func getCount() -> Int
    func IsUsingSegments() -> Bool
}

// One instance per client
class DefaultByKeyMySegmentsStorage: ByKeyMySegmentsStorage {

    private let mySegmentsStorage: MySegmentsStorage
    private let userKey: String

    var changeNumber: Int64 {
        return mySegmentsStorage.changeNumber(forKey: userKey) ?? -1
    }

    init(mySegmentsStorage: MySegmentsStorage,
         userKey: String) {
        self.mySegmentsStorage = mySegmentsStorage
        self.userKey = userKey
    }

    func loadLocal() {
        let start = Date.nowMillis()
        mySegmentsStorage.loadLocal(forKey: userKey)
        TimeChecker.logInterval("Time to load segments from cache", startTime: start)
    }

    func getAll() -> Set<String> {
        return mySegmentsStorage.getAll(forKey: userKey)
    }

    func set(_ change: SegmentChange) {
        mySegmentsStorage.set(change, forKey: userKey)
    }

    func getCount() -> Int {
        return mySegmentsStorage.getCount(forKey: userKey)
    }
     
    // MARK: Segments in use Optimization
    func IsUsingSegments() -> Bool {
        mySegmentsStorage.IsUsingSegments()
    }
}
