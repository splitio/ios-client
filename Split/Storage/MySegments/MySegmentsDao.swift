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

    private let cipher: Cipher?
    init(coreDataHelper: CoreDataHelper, cipher: Cipher? = nil) {
        self.cipher = cipher
        super.init(coreDataHelper: coreDataHelper)
    }

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

            let searchKey = self.cipher?.encrypt(userKey) ?? userKey
            if let entity = self.getByUserKey(userKey) ??
                self.coreDataHelper.create(entity: .mySegment) as? MySegmentEntity {
                let segmentListString = segmentList.joined(separator: ",")
                entity.userKey = searchKey
                entity.segmentList = self.cipher?.encrypt(segmentListString) ?? segmentListString
                self.coreDataHelper.save()
            }
        }
    }

    private func getByUserKey(_ userKey: String) -> MySegmentEntity? {
        let predicate = NSPredicate(format: "userKey == %@", cipher?.encrypt(userKey) ?? userKey)
        let entities = self.coreDataHelper.fetch(entity: .mySegment,
                                                 where: predicate).compactMap { return $0 as? MySegmentEntity }
        if entities.count > 0 {
            return entities[0]
        }
        return nil
    }

    private func mapEntityToModel(_ entity: MySegmentEntity) -> [String] {
        let segmentListString = cipher?.decrypt(entity.segmentList) ?? entity.segmentList
        if let parsedSegmentList = segmentListString?.split(separator: ",") {
            return parsedSegmentList.map { String($0) }
        }
        return []
    }
}
