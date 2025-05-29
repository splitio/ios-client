//
//  ImpressionDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import CoreData
import Foundation

protocol ImpressionDao {
    func insert(_ impression: KeyImpression)
    func insert(_ impressions: [KeyImpression])
    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [KeyImpression]
    func update(ids: [String], newStatus: Int32)
    func delete(_ impressions: [KeyImpression])
}

class CoreDataImpressionDao: BaseCoreDataDao, ImpressionDao {
    private let cipher: Cipher?
    init(coreDataHelper: CoreDataHelper, cipher: Cipher? = nil) {
        self.cipher = cipher
        super.init(coreDataHelper: coreDataHelper)
    }

    func insert(_ impression: KeyImpression) {
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.insert(impression: impression)
        }
    }

    func insert(_ impressions: [KeyImpression]) {
        executeAsync { [weak self] in
            guard let self = self else { return }
            for impression in impressions {
                self.insert(impression: impression)
            }
        }
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [KeyImpression] {
        var result = [KeyImpression]()
        execute { [weak self] in
            guard let self = self else {
                return
            }

            let predicate = NSPredicate(format: "createdAt >= %d AND status == %d", createdAt, status)
            let entities = self.coreDataHelper.fetch(
                entity: .impression,
                where: predicate,
                rowLimit: maxRows).compactMap { $0 as? ImpressionEntity }

            entities.forEach { entity in
                if let model = try? self.mapEntityToModel(entity) {
                    result.append(model)
                }
            }
        }
        return result
    }

    func update(ids: [String], newStatus: Int32) {
        if ids.isEmpty {
            return
        }

        let predicate = NSPredicate(format: "storageId IN %@", ids)

        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            let entities = self.coreDataHelper.fetch(
                entity: .impression,
                where: predicate).compactMap { $0 as? ImpressionEntity }
            for entity in entities {
                entity.status = newStatus
            }
            self.coreDataHelper.save()
        }
    }

    func delete(_ impressions: [KeyImpression]) {
        if impressions.isEmpty {
            return
        }
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.delete(
                entity: .impression,
                by: "storageId",
                values: impressions.map { $0.storageId ?? "" })
            self.coreDataHelper.save()
        }
    }

    // Use this function wrapped by "execute" or "executeAsync" functions!!
    private func insert(impression: KeyImpression) {
        if let obj = coreDataHelper.create(entity: .impression) as? ImpressionEntity {
            do {
                let featureName = cipher?.encrypt(impression.featureName) ?? impression.featureName
                guard let testName = featureName else {
                    // This should never happen
                    Logger.d("Impression without test name descarted")
                    return
                }
                obj.storageId = coreDataHelper.generateId()
                obj.testName = testName
                let body = try Json.encodeToJson(impression)
                obj.body = cipher?.encrypt(body) ?? body
                obj.createdAt = Date().unixTimestamp()
                obj.status = StorageRecordStatus.active
                // Saving one by one to avoid losing all
                // if an error occurs
                coreDataHelper.save()
            } catch {
                Logger.e("""
                An error occurred while inserting impressions in storage:
                \(error.localizedDescription)
                """)
            }
        }
    }

    private func mapEntityToModel(_ entity: ImpressionEntity) throws -> KeyImpression {
        let body = cipher?.decrypt(entity.body) ?? entity.body
        let testName = cipher?.decrypt(entity.testName) ?? entity.testName
        do {
            var model = try Json.decodeFrom(json: body, to: KeyImpression.self)
            model.storageId = entity.storageId
            model.featureName = testName
            return model
        } catch {
            // if an error occurrs try with deprecated property parsing
            var model = try Json.decodeFrom(json: body, to: DeprecatedImpression.self)
            model.storageId = entity.storageId
            model.featureName = testName
            return model.toKeyImpression()
        }
    }
}
