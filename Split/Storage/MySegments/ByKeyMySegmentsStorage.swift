//
//  ByKeyMySegmentsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 03-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol ByKeyMySegmentsStorage: SegmentsChecker {
    var changeNumber: Int64 { get }
    func loadLocal()
    func getAll() -> Set<String>
    func set(_ change: SegmentChange)
    func getCount() -> Int
}

// One instance per client
class DefaultByKeyMySegmentsStorage: ByKeyMySegmentsStorage, @unchecked Sendable {

    private let mySegmentsStorage: MySegmentsStorage
    private let userKey: String
    private let timeChecker: TimeChecker

    var changeNumber: Int64 {
        return mySegmentsStorage.changeNumber(forKey: userKey) ?? -1
    }

    init(mySegmentsStorage: MySegmentsStorage,
         userKey: String,
         timeChecker: TimeChecker) {
        self.mySegmentsStorage = mySegmentsStorage
        self.userKey = userKey
        self.timeChecker = timeChecker
    }

    func loadLocal() {
        let start = Date.nowMillis()
        mySegmentsStorage.loadLocal(forKey: userKey)
        timeChecker.logInterval("Time to load segments from cache", since: start)
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
     
    // MARK: For Network Traffic Optimization
    func isUsingSegments() -> Bool {
        mySegmentsStorage.isUsingSegments()
    }
}
