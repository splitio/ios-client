//
//  EventDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import CoreData

protocol EventDao {
    func insert(_ event: EventDTO)
    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [EventDTO]
    func update(ids: [String], newStatus: Int32)
    func delete(_ events: [EventDTO])
}

class CoreDataEventDao: EventDao {

    let coreDataHelper: CoreDataHelper

    init(coreDataHelper: CoreDataHelper) {
        self.coreDataHelper = coreDataHelper
    }

    func insert(_ event: EventDTO) {
        if let obj = coreDataHelper.create(entity: .event) as? EventEntity {
            do {
                obj.storageId = coreDataHelper.generateId()
                obj.body = try Json.dynamicEncodeToJson(event)
                obj.createdAt = Date().unixTimestamp()
                obj.status = StorageRecordStatus.active
                coreDataHelper.save()
            } catch {
                Logger.e("An error occurred while inserting events in storage: \(error.localizedDescription)")
            }
        }
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [EventDTO] {
        var result = [EventDTO]()
        let predicate = NSPredicate(format: "createdAt >= %d AND status == %d", createdAt, status)
        let entities = coreDataHelper.fetch(entity: .event,
                                            where: predicate,
                                            rowLimit: maxRows).compactMap { return $0 as? EventEntity }

        entities.forEach { entity in
            if let model = try? mapEntityToModel(entity) {
                result.append(model)
            }
        }

        return result
    }

    func update(ids: [String], newStatus: Int32) {
        let predicate = NSPredicate(format: "storageId IN %@", ids)
        let entities = coreDataHelper.fetch(entity: .event,
                                            where: predicate).compactMap { return $0 as? EventEntity }
        for entity in entities {
            entity.status = newStatus
        }
        coreDataHelper.save()
    }

    func delete(_ events: [EventDTO]) {
        coreDataHelper.delete(entity: .event, by: "storageId", values: events.map { $0.storageId ?? "" })
    }

    func mapEntityToModel(_ entity: EventEntity) throws -> EventDTO {
        let model = try Json.dynamicEncodeFrom(json: entity.body, to: EventDTO.self)
        model.storageId = entity.storageId
        return model
    }
}
