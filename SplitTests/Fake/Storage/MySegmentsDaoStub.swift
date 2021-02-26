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
    var segments =  [String: [String]]()
    func getBy(userKey: String) -> [String] {
        return segments[userKey] ?? []
    }
    
    func update(userKey: String, segmentList: [String]) {
        segments[userKey] = segmentList
    }
}
