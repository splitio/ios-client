//
//  MySegmentDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import CoreData

protocol MyLargeSegmentsDao {
    func getBy(userKey: String) -> SegmentChange?
    func update(userKey: String, change: SegmentChange)
}

/// Added a new parameter to specify the entity to work with.
/// Since Segments and LargeSegments are handled the same way,
/// it is not necessary to create a new DAO class for them.
class CoreDataMyLargeSegmentsDao: BaseCoreDataDao, MyLargeSegmentsDao {

    private let coreDataEntity = CoreDataEntity.myLargeSegment
    private let cipher: Cipher?
    init(coreDataHelper: CoreDataHelper,
         cipher: Cipher? = nil) {
        self.cipher = cipher
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
                self.coreDataHelper.create(entity: coreDataEntity) as? MyLargeSegmentEntity {
                do {
                    let body = try Json.encodeToJson(change)
                    entity.userKey = searchKey
                    entity.body = self.cipher?.encrypt(body) ?? body
                    self.coreDataHelper.save()
                } catch {
                    Logger.e("Error encoding large segment: \(error)")
                }
            }
        }
    }

    private func getByUserKey(_ userKey: String) -> MyLargeSegmentEntity? {
        let predicate = NSPredicate(format: "userKey == %@", cipher?.encrypt(userKey) ?? userKey)
        let entities = self.coreDataHelper.fetch(entity: coreDataEntity,
                                                 where: predicate).compactMap { return $0 as? MyLargeSegmentEntity }
        if entities.count > 0 {
            return entities[0]
        }
        return nil
    }

    private func mapEntityToModel(_ entity: MyLargeSegmentEntity) -> SegmentChange? {
        let changeJson = cipher?.decrypt(entity.body) ?? entity.body
        if let changeJson = changeJson {
            do {
                return try Json.decodeFrom(json: changeJson, to: SegmentChange.self)
            } catch {
                Logger.e("Something happen parsing MyLargeSegment: \(error) - \(changeJson)")
            }
        }
        return nil
    }
}
