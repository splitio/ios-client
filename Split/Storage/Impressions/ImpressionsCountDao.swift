//
//  ImpressionsCountDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 29-Jun-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import CoreData
import Foundation

protocol ImpressionsCountDao {
    func insert(_ count: ImpressionsCountPerFeature)
    func insert(_ counts: [ImpressionsCountPerFeature])
    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [ImpressionsCountPerFeature]
    func update(ids: [String], newStatus: Int32)
    func delete(_ counts: [ImpressionsCountPerFeature])
}

class CoreDataImpressionsCountDao: BaseCoreDataDao, ImpressionsCountDao {
    private let cipher: Cipher?
    init(coreDataHelper: CoreDataHelper, cipher: Cipher? = nil) {
        self.cipher = cipher
        super.init(coreDataHelper: coreDataHelper)
    }

    func insert(_ count: ImpressionsCountPerFeature) {
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.insert(count: count)
        }
    }

    func insert(_ counts: [ImpressionsCountPerFeature]) {
        if counts.isEmpty {
            return
        }
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            for count in counts {
                self.insert(count: count)
            }
            self.coreDataHelper.save()
        }
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [ImpressionsCountPerFeature] {
        var result = [ImpressionsCountPerFeature]()
        execute { [weak self] in
            guard let self = self else {
                return
            }

            let predicate = NSPredicate(format: "createdAt >= %d AND status == %d", createdAt, status)
            let entities = self.coreDataHelper.fetch(
                entity: .impressionsCount,
                where: predicate,
                rowLimit: maxRows)
                .compactMap { $0 as? ImpressionsCountEntity }

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
            let entities =
                self.coreDataHelper.fetch(
                    entity: .impressionsCount,
                    where: predicate).compactMap { $0 as? ImpressionsCountEntity }
            for entity in entities {
                entity.status = newStatus
            }
            self.coreDataHelper.save()
        }
    }

    func delete(_ counts: [ImpressionsCountPerFeature]) {
        if counts.isEmpty {
            return
        }
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.delete(
                entity: .impressionsCount,
                by: "storageId",
                values: counts.map { $0.storageId ?? "" })
            self.coreDataHelper.save()
        }
    }

    private func insert(count: ImpressionsCountPerFeature) {
        if let obj = coreDataHelper.create(entity: .impressionsCount) as? ImpressionsCountEntity {
            do {
                obj.storageId = coreDataHelper.generateId()
                let body = try Json.encodeToJson(count)
                obj.body = cipher?.encrypt(body) ?? body
                obj.createdAt = Date().unixTimestamp()
                obj.status = StorageRecordStatus.active
                coreDataHelper.save()
            } catch {
                Logger.e(
                    "An error occurred while inserting impressions " +
                        "counts in storage: \(error.localizedDescription)")
            }
        }
    }

    private func mapEntityToModel(_ entity: ImpressionsCountEntity) throws -> ImpressionsCountPerFeature {
        let body = cipher?.decrypt(entity.body) ?? entity.body
        var model = try Json.decodeFrom(json: body, to: ImpressionsCountPerFeature.self)
        model.storageId = entity.storageId
        return model
    }
}
