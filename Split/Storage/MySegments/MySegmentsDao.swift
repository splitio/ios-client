//
//  MySegmentDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import CoreData

protocol MySegmentsDao {
    func getBy(userKey: String) -> [String]
    func update(userKey: String, segmentList: [String])
}

class CoreDataMySegmentsDao: BaseCoreDataDao, MySegmentsDao {

    func getBy(userKey: String) -> [String] {
        var mySegments = [String]()
        execute { [weak self] in
            guard let self = self else {
                return
            }

            if let entity = self.getByUserKey(userKey) {
                mySegments.append(contentsOf: self.mapEntityToModel(entity))
            }
        }
        return mySegments
    }

    func update(userKey: String, segmentList: [String]) {

        executeAsync { [weak self] in
            guard let self = self else {
                return
            }

            if let entity = self.getByUserKey(userKey) ??
                self.coreDataHelper.create(entity: .mySegment) as? MySegmentEntity {
                entity.userKey = userKey
                entity.segmentList = segmentList.joined(separator: ",")
                self.coreDataHelper.save()
            }
        }
    }

    private func getByUserKey(_ userKey: String) -> MySegmentEntity? {
        let predicate = NSPredicate(format: "userKey == %@", userKey)
        let entities = self.coreDataHelper.fetch(entity: .mySegment,
                                                 where: predicate).compactMap { return $0 as? MySegmentEntity }
        if entities.count > 0 {
            return entities[0]
        }
        return nil
    }

    private func mapEntityToModel(_ entity: MySegmentEntity) -> [String] {
        if let parsedSegmentList = entity.segmentList?.split(separator: ",") {
            return parsedSegmentList.map { String($0) }
        }
        return []
    }
}
