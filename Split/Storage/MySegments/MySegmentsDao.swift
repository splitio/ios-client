//
//  MySegmentDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import CoreData
import Foundation

protocol MySegmentsDao {
    func getBy(userKey: String) -> SegmentChange?
    func update(userKey: String, change: SegmentChange)
    func deleteAll()
}

/// Added a new parameter to specify the entity to work with.
/// Since Segments and LargeSegments are handled the same way,
/// it is not necessary to create a new DAO class for them.
class CoreDataMySegmentsDao: BaseCoreDataDao, MySegmentsDao {
    private let coreDataEntity: CoreDataEntity
    private let cipher: Cipher?
    init(
        coreDataHelper: CoreDataHelper,
        entity: CoreDataEntity,
        cipher: Cipher? = nil) {
        self.cipher = cipher
        self.coreDataEntity = entity
        super.init(coreDataHelper: coreDataHelper)
    }

    func getBy(userKey: String) -> SegmentChange? {
        var change: SegmentChange?
        execute { [weak self] in
            guard let self = self else {
                return
            }

            if let entity = self.getByUserKey(userKey) {
                change = self.mapEntityToModel(entity)
            }
        }
        return change
    }

    func update(userKey: String, change: SegmentChange) {
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }

            let searchKey = self.cipher?.encrypt(userKey) ?? userKey
            if let entity = self.getByUserKey(userKey) ??
                self.coreDataHelper.create(entity: coreDataEntity) as? MySegmentEntity {
                do {
                    let body = try Json.encodeToJson(change)
                    entity.userKey = searchKey
                    entity.segmentList = self.cipher?.encrypt(body) ?? body
                    self.coreDataHelper.save()
                } catch {
                    Logger.e("Error encoding large segment: \(error)")
                }
            }
        }
    }

    func deleteAll() {
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.deleteAll(entity: coreDataEntity)
        }
    }

    private func getByUserKey(_ userKey: String) -> MySegmentEntity? {
        let predicate = NSPredicate(format: "userKey == %@", cipher?.encrypt(userKey) ?? userKey)
        let entities = coreDataHelper.fetch(
            entity: coreDataEntity,
            where: predicate).compactMap { $0 as? MySegmentEntity }
        if !entities.isEmpty {
            return entities[0]
        }
        return nil
    }

    private func mapEntityToModel(_ entity: MySegmentEntity) -> SegmentChange? {
        // Here is necessary to handle old Segment List format
        let changeJson = cipher?.decrypt(entity.segmentList) ?? entity.segmentList
        if let changeJson = changeJson {
            do {
                // First try to parse a Json
                return try Json.decodeFrom(json: changeJson, to: SegmentChange.self)
            } catch {
                // If error, check if segment list
                return changeFromSegmentList(changeJson)
            }
        }
        return nil
    }

    private func changeFromSegmentList(_ segmentList: String) -> SegmentChange? {
        let segments = segmentList.split(separator: ",").map { String($0) }
        return SegmentChange(segments: segments)
    }
}
