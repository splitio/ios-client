//
//  ImpressionDaoStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class ImpressionDaoStub: ImpressionDao {
    var insertedImpressions = [KeyImpression]()
    var getByImpressions = [KeyImpression]()
    var updatedImpressions = [String: Int32]()
    var deletedImpressions = [KeyImpression]()

    func insert(_ impression: KeyImpression) {
        insertedImpressions.append(impression)
    }

    func insert(_ impressions: [KeyImpression]) {
        insertedImpressions.append(contentsOf: impressions)
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [KeyImpression] {
        return getByImpressions
    }

    func update(ids: [String], newStatus: Int32) {
        ids.forEach {
            updatedImpressions[$0] = newStatus
        }
    }

    func delete(_ impressions: [KeyImpression]) {
        deletedImpressions.append(contentsOf: impressions)
    }
}
