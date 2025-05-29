//
//  UniqueKeyDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 17-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import CoreData
import Foundation

protocol UniqueKeyDao {
    func insert(_ key: UniqueKey)
    func insert(_ keys: [UniqueKey])
    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [UniqueKey]
    func update(ids: [String], newStatus: Int32, incrementSentCount: Bool)
    func delete(_ ids: [String])
}

class CoreDataUniqueKeyDao: BaseCoreDataDao, UniqueKeyDao {
    private let cipher: Cipher?
    init(coreDataHelper: CoreDataHelper, cipher: Cipher? = nil) {
        self.cipher = cipher
        super.init(coreDataHelper: coreDataHelper)
    }

    func insert(_ key: UniqueKey) {
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.insert(key: key)
        }
    }

    func insert(_ keys: [UniqueKey]) {
        if keys.isEmpty {
            return
        }
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            for key in keys {
                self.insert(key: key)
            }
            self.coreDataHelper.save()
        }
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [UniqueKey] {
        var result = [UniqueKey]()
        execute { [weak self] in
            guard let self = self else {
                return
            }

            let predicate = NSPredicate(format: "createdAt >= %d AND status == %d", createdAt, status)
            let entities = self.coreDataHelper.fetch(
                entity: .uniqueKey,
                where: predicate,
                rowLimit: maxRows).compactMap { $0 as? UniqueKeyEntity }

            entities.forEach { entity in
                if let model = try? self.mapEntityToModel(entity) {
                    result.append(model)
                }
            }
        }
        return result
    }

    func update(ids: [String], newStatus: Int32, incrementSentCount: Bool) {
        if ids.isEmpty {
            return
        }

        let predicate = NSPredicate(format: "storageId IN %@", ids)

        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            let entities =
                self.coreDataHelper.fetch(
                    entity: .uniqueKey,
                    where: predicate).compactMap { $0 as? UniqueKeyEntity }

            var toDelete = [String]()
            for entity in entities {
                entity.status = newStatus
                if incrementSentCount {
                    entity.sendAttemptCount += 1
                    if entity.sendAttemptCount > ServiceConstants.retryCount {
                        toDelete.append(entity.storageId)
                    }
                }
            }
            self.coreDataHelper.delete(
                entity: .uniqueKey,
                by: "storageId",
                values: toDelete)
            self.coreDataHelper.save()
        }
    }

    func delete(_ ids: [String]) {
        if ids.isEmpty {
            return
        }
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.delete(
                entity: .uniqueKey,
                by: "storageId",
                values: ids)
            self.coreDataHelper.save()
        }
    }

    private func mapEntityToModel(_ entity: UniqueKeyEntity) throws -> UniqueKey {
        let userKey = cipher?.decrypt(entity.userKey) ?? entity.userKey
        let json = cipher?.decrypt(entity.featureList) ?? entity.featureList
        let featureList = try Json.decodeFrom(json: json, to: [String].self)
        let model = UniqueKey(
            storageId: entity.storageId,
            userKey: userKey,
            features: Set(featureList))
        return model
    }

    // Call this function within an "execute" or "executeAsync"
    private func insert(key: UniqueKey) {
        if let obj = coreDataHelper.create(entity: .uniqueKey) as? UniqueKeyEntity {
            do {
                obj.storageId = coreDataHelper.generateId()
                obj.userKey = cipher?.encrypt(key.userKey) ?? key.userKey
                let featureList = try Json.encodeToJson(key.features)
                obj.featureList = cipher?.encrypt(featureList) ?? featureList
                obj.createdAt = Date().unixTimestamp()
                obj.status = StorageRecordStatus.active
                coreDataHelper.save()
            } catch {
                Logger.e(
                    "An error occurred while inserting unique keys " +
                        "in storage: \(error.localizedDescription)")
            }
        }
    }
}
