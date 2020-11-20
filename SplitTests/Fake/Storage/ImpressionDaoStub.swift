//
//  ImpressionDaoStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

@testable import Split
import Foundation

class ImpressionDaoStub: ImpressionDao {

    var insertedImpressions = [Impression]()
    var getByImpressions = [Impression]()
    var updatedImpressions = [String: Int32]()
    var deletedImpressions = [Impression]()

    func insert(_ event: Impression) {
        insertedImpressions.append(event)
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [Impression] {
        return getByImpressions
    }

    func update(ids: [String], newStatus: Int32) {
        ids.forEach {
            updatedImpressions[$0] = newStatus
        }
    }

    func delete(_ events: [Impression]) {
        deletedImpressions.append(contentsOf: events)
    }
}
