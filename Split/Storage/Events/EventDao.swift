//
//  EventDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import CoreData
import Foundation

protocol EventDao {
    func insert(_ event: EventDTO)
    func insert(_ events: [EventDTO])
    func getBy(createdAt: Int64, status: Int32, maxRows: Int) -> [EventDTO]
    func update(ids: [String], newStatus: Int32)
    func delete(_ events: [EventDTO])
}

class CoreDataEventDao: BaseCoreDataDao, EventDao {
    private let cipher: Cipher?
    init(coreDataHelper: CoreDataHelper, cipher: Cipher? = nil) {
        self.cipher = cipher
        super.init(coreDataHelper: coreDataHelper)
    }

    func insert(_ event: EventDTO) {
        execute { [weak self] in
            guard let self = self else {
                return
            }
            self.insert(event: event)
        }
    }

    func insert(_ events: [EventDTO]) {
        executeAsync { [weak self] in
            guard let self = self else { return }
            for event in events {
                self.insert(event: event)
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
            let entities = self.coreDataHelper.fetch(
                entity: .event,
                where: predicate,
                rowLimit: maxRows).compactMap { $0 as? EventEntity }

            events = entities.compactMap { try? self.mapEntityToModel($0) }
        }
        return events ?? []
    }

    func update(ids: [String], newStatus: Int32) {
        let predicate = NSPredicate(format: "storageId IN %@", ids)
        execute { [weak self] in
            guard let self = self else {
                return
            }
            let entities = self.coreDataHelper.fetch(
                entity: .event,
                where: predicate).compactMap { $0 as? EventEntity }
            for entity in entities {
                entity.status = newStatus
            }
            self.coreDataHelper.save()
        }
    }

    func delete(_ events: [EventDTO]) {
        if events.isEmpty {
            return
        }
        execute { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.delete(entity: .event, by: "storageId", values: events.map { $0.storageId ?? "" })
            self.coreDataHelper.save()
        }
    }

    private func mapEntityToModel(_ entity: EventEntity) throws -> EventDTO {
        let body = cipher?.decrypt(entity.body) ?? entity.body
        let model = try Json.dynamicDecodeFrom(json: body, to: EventDTO.self)
        model.storageId = entity.storageId
        model.sizeInBytes = entity.sizeInBytes
        return model
    }

    // Call this function within an "execute" or "executeAsync"
    private func insert(event: EventDTO) {
        if let obj = coreDataHelper.create(entity: .event) as? EventEntity {
            do {
                obj.storageId = coreDataHelper.generateId()
                let body = try Json.dynamicEncodeToJson(event)
                obj.body = cipher?.encrypt(body) ?? body
                obj.createdAt = Date().unixTimestamp()
                obj.status = StorageRecordStatus.active
                coreDataHelper.save()
            } catch {
                Logger.e("An error occurred while inserting events in storage: \(error.localizedDescription)")
            }
        }
    }
}
