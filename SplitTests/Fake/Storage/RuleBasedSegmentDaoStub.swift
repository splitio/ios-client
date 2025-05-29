//
//  RuleBasedSegmentDaoStub.swift
//  SplitTests
//
//  Created by Split on 14/03/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation
@testable import Split

class RuleBasedSegmentDaoStub: RuleBasedSegmentDao {
    var insertedSegments = [RuleBasedSegment]()
    var segments = [RuleBasedSegment]()
    var deletedSegments: [String]?
    var deleteAllCalled = false

    func insertOrUpdate(segments: [RuleBasedSegment]) {
        insertedSegments = segments
    }

    func syncInsertOrUpdate(segment: RuleBasedSegment) {
        insertOrUpdate(segment: segment)
    }

    func insertOrUpdate(segment: RuleBasedSegment) {
        insertedSegments.append(segment)
    }

    func getAll() -> [RuleBasedSegment] {
        return segments
    }

    func delete(_ segments: [String]) {
        deletedSegments = segments
    }

    func deleteAll() {
        deleteAllCalled = true
    }
}
