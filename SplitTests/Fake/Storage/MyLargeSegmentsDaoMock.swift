//
//  MyLargeSegmentsDaoMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 27/11/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split

class MyLargeSegmentsDaoMock: MyLargeSegmentsDao {
    var segments =  [String: SegmentChange]()
    func getBy(userKey: String) -> SegmentChange? {
        return segments[userKey]
    }
    
    func update(userKey: String, change: SegmentChange) {
        segments[userKey] = change
    }
}
