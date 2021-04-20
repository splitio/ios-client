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

class CoreDataEventDao: BaseCoreDataDao, EventDao {

    func insert(_ event: EventDTO) {
        execute { [weak self] in
            guard let self = self else {
                return
            }

            if let obj = self.coreDataHelper.create(entity: .event) as? EventEntity {
                do {
                    obj.storageId = self.coreDataHelper.generateId()
                    obj.body = try Json.dynamicEncodeToJson(event)
                    obj.createdAt = Date().unixTimestamp()
                    obj.status = StorageRecordStatus.active
                    self.coreDataHelper.save()
                } catch {
                    Logger.e("An error occurred while inserting events in storage: \(error.localizedDescription)")
                }
            }
        }
    }

    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [EventDTO] {
        var events: [EventDTO]?
        execute { [weak self] in
            guard let self = self else {
                return
            }
            let predicate = NSPredicate(format: "createdAt >= %d AND status == %d", createdAt, status)
            let entities = self.coreDataHelper.fetch(entity: .event,
                                                     where: predicate,
                                                     rowLimit: maxRows).compactMap { return $0 as? EventEntity }

            events = entities.compactMap { return try? self.mapEntityToModel($0) }
        }
        return events ?? []
    }

    func update(ids: [String], newStatus: Int32) {
        let predicate = NSPredicate(format: "storageId IN %@", ids)
        execute { [weak self] in
            guard let self = self else {
                return
            }
            let entities = self.coreDataHelper.fetch(entity: .event,
                                                where: predicate).compactMap { return $0 as? EventEntity }
            for entity in entities {
                entity.status = newStatus
            }
            self.coreDataHelper.save()
        }
    }

    func delete(_ events: [EventDTO]) {
        if events.count == 0 {
            return
        }
        execute { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.delete(entity: .event, by: "storageId", values: events.map { $0.storageId ?? "" })
        }
    }

    private func mapEntityToModel(_ entity: EventEntity) throws -> EventDTO {
        let model = try Json.dynamicEncodeFrom(json: entity.body, to: EventDTO.self)
        model.storageId = entity.storageId
        model.sizeInBytes = entity.sizeInBytes
        return model
    }
}
