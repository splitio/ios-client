//
//  ImpressionsCountDaoStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 30-Jun-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split

class ImpressionsCountDaoStub: ImpressionsCountDao {
    var insertedCounts = [ImpressionsCountPerFeature]()
    var getByCounts = [ImpressionsCountPerFeature]()
    var updatedCounts = [String: Int32]()
    var deletedCounts = [ImpressionsCountPerFeature]()

    func insert(_ count: ImpressionsCountPerFeature) {
        insertedCounts.append(count)
    }

    func insert(_ counts: [ImpressionsCountPerFeature]) {
        insertedCounts.append(contentsOf: counts)
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [ImpressionsCountPerFeature] {
        return getByCounts
    }

    func update(ids: [String], newStatus: Int32) {
        ids.forEach {
            updatedCounts[$0] = newStatus
        }
    }

    func delete(_ events: [ImpressionsCountPerFeature]) {
        deletedCounts.append(contentsOf: events)
    }
}
