//
//  MySegmentsDaoStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 27/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class MySegmentsDaoStub: MySegmentsDao {
    var segments =  [String: SegmentChange]()
    var deleteAllCalled = false
    func getBy(userKey: String) -> SegmentChange? {
        return segments[userKey]
    }
    
    func update(userKey: String, change: SegmentChange) {
        segments[userKey] = change
    }

    func deleteAll() {
        deleteAllCalled = true
    }
}
