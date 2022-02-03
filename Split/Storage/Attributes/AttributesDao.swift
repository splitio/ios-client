//
//  AttributeDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import CoreData

protocol AttributesDao {
    func getBy(userKey: String) -> [String: Any]?
    func update(userKey: String, attributes: [String: Any]?)
    func syncUpdate(userKey: String, attributes: [String: Any]?)
}

class CoreDataAttributesDao: BaseCoreDataDao, AttributesDao {
    func getBy(userKey: String) -> [String: Any]? {
        var attributes: [String: Any]?
        execute { [weak self] in
            guard let self = self else {
                return
            }

            if let entity = self.getByUserKey(userKey) {
                attributes = self.mapEntityToModel(entity)
            }
        }
        return attributes
    }

    func update(userKey: String, attributes: [String: Any]?) {
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.updateAttributes(attributes, userKey: userKey)
        }
    }

    // For testing purposes only
    func syncUpdate(userKey: String, attributes: [String: Any]?) {

        execute { [weak self] in
            guard let self = self else {
                return
            }
            self.updateAttributes(attributes, userKey: userKey)
        }
    }

    private func updateAttributes(_ attributes: [String: Any]?, userKey: String) {
        guard let attributes = attributes else {
            self.coreDataHelper.delete(entity: .attribute, by: "userKey",
                                       values: [userKey])
            return
        }

        if let entity = self.getByUserKey(userKey) ??
            self.coreDataHelper.create(entity: .attribute) as? AttributeEntity {
            entity.userKey = userKey
            do {
                entity.attributes = try Json.dynamicEncodeToJson(AttributeMap(attributes: attributes))
            } catch {
                Logger.e("Error while parsing attributes to store them in DB: \(error)")
            }
            self.coreDataHelper.save()
        }
    }

    private func getByUserKey(_ userKey: String) -> AttributeEntity? {
        let predicate = NSPredicate(format: "userKey == %@", userKey)
        let entities = self.coreDataHelper.fetch(entity: .attribute,
                                                 where: predicate).compactMap { return $0 as? AttributeEntity }
        if entities.count > 0 {
            return entities[0]
        }
        return nil
    }

    private func mapEntityToModel(_ entity: AttributeEntity) -> [String: Any]? {
        do {
            if let attributes = entity.attributes {
                let attributeMap = try Json.dynamicEncodeFrom(json: attributes, to: AttributeMap.self)
                return attributeMap.attributes
            }
        } catch {
            Logger.e("Something happened when loading attributes from cache: \(error)")
        }
        return nil
    }
}
