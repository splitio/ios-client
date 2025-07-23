//
//  EmptyMySegmentsStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 11/01/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

class EmptyMySegmentsStorage: MySegmentsStorage {
    
    func changeNumber(forKey key: String) -> Int64? {
       return -1
    }

    var changeNumber: Int64 = -1

    func lowerChangeNumber() -> Int64 {
        return -1
    }

    func set(_ change: SegmentChange, forKey key: String) {
    }

    var keys: Set<String> = Set()

    func loadLocal(forKey key: String) {
    }

    func getAll(forKey key: String) -> Set<String> {
        return Set()
    }

    func clear(forKey key: String) {
    }

    func destroy() {
    }

    func getCount(forKey key: String) -> Int {
        return 0
    }

    func getCount() -> Int {
        return 0
    }

    func clear() {
    }
    
    func IsUsingSegments() -> Bool {
        false
    }
}
