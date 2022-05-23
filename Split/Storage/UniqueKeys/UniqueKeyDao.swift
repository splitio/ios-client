//
//  UniqueKeyDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 17-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
import CoreData

protocol UniqueKeyDao {
    func insert(_ key: UniqueKey)
    func insert(_ keys: [UniqueKey])
    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [UniqueKey]
    func update(ids: [String], newStatus: Int32, incrementSentCount: Bool)
    func delete(_ ids: [String])
}

class CoreDataUniqueKeyDao: BaseCoreDataDao, UniqueKeyDao {

    let json = JsonWrapper()

    func insert(_ key: UniqueKey) {

        executeAsync { [weak self] in
            guard let self = self else {
                return
            }

            if let obj = self.coreDataHelper.create(entity: .uniqueKey) as? UniqueKeyEntity {
                do {
                    obj.storageId = self.coreDataHelper.generateId()
                    obj.userKey = key.userKey
                    obj.featureList = try self.json.encodeToJson(key.features)
                    obj.createdAt = Date().unixTimestamp()
                    obj.status = StorageRecordStatus.active
                    self.coreDataHelper.save()
                } catch {
                    Logger.e("An error occurred while inserting unique keys " +
                                "in storage: \(error.localizedDescription)")
                }
            }
        }
    }

    func insert(_ keys: [UniqueKey]) {
        if keys.count == 0 {
            return
        }
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            do {
                for key in keys {
                    if let obj = self.coreDataHelper.create(entity: .uniqueKey) as? UniqueKeyEntity {
                        obj.storageId = self.coreDataHelper.generateId()
                        obj.userKey = key.userKey
                        obj.featureList = try self.json.encodeToJson(key.features)
                        obj.createdAt = Date().unixTimestamp()
                        obj.status = StorageRecordStatus.active
                        obj.sendAttemptCount = 0
                    }
                }
                self.coreDataHelper.save()
            } catch {
                Logger.e("An error occurred while inserting uniqueKeys " +
                            "in storage: \(error.localizedDescription)")
            }
        }
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [UniqueKey] {
        var result = [UniqueKey]()
        execute { [weak self] in
            guard let self = self else {
                return
            }

            let predicate = NSPredicate(format: "createdAt >= %d AND status == %d", createdAt, status)
            let entities = self.coreDataHelper.fetch(entity: .uniqueKey,
                                                where: predicate,
                                                rowLimit: maxRows).compactMap { return $0 as? UniqueKeyEntity }

            entities.forEach { entity in
                if let model = try? self.mapEntityToModel(entity) {
                    result.append(model)
                }
            }
        }
        return result
    }

    func update(ids: [String], newStatus: Int32, incrementSentCount: Bool) {
        if ids.count == 0 {
            return
        }

        let predicate = NSPredicate(format: "storageId IN %@", ids)

        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            let entities =
                self.coreDataHelper.fetch(entity: .uniqueKey,
                                          where: predicate).compactMap { return $0 as? UniqueKeyEntity }

            var toDelete = [String]()
            for entity in entities {
                entity.status = newStatus
                if incrementSentCount {
                    entity.sendAttemptCount+=1
                    if entity.sendAttemptCount > ServiceConstants.retryCount {
                        toDelete.append(entity.storageId)
                    }
                }
            }
            self.delete(toDelete)
            self.coreDataHelper.save()
        }
    }

    func delete(_ ids: [String]) {
        if ids.count == 0 {
            return
        }
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.delete(entity: .uniqueKey, by: "storageId",
                                       values: ids)
        }
    }

    func mapEntityToModel(_ entity: UniqueKeyEntity) throws -> UniqueKey {
        let featureList = try Json.encodeFrom(json: entity.featureList, to: [String].self)
        let model = UniqueKey(storageId: entity.storageId,
                              userKey: entity.userKey,
                              features: Set(featureList))
        return model
    }
}
