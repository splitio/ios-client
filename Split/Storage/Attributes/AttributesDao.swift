//
//  AttributeDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import CoreData
import Foundation

protocol AttributesDao {
    func getBy(userKey: String) -> [String: Any]?
    func update(userKey: String, attributes: [String: Any]?)
    func syncUpdate(userKey: String, attributes: [String: Any]?)
}

class CoreDataAttributesDao: BaseCoreDataDao, AttributesDao {
    private let cipher: Cipher?
    init(coreDataHelper: CoreDataHelper, cipher: Cipher? = nil) {
        self.cipher = cipher
        super.init(coreDataHelper: coreDataHelper)
    }

    func getBy(userKey: String) -> [String: Any]? {
        var attributes: [String: Any]?
        execute { [weak self] in
            guard let self = self else {
                return
            }

            if let entity = self.getByUserKey(self.cipher?.encrypt(userKey) ?? userKey) {
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
        let encUserKey = cipher?.encrypt(userKey) ?? userKey
        guard let attributes = attributes else {
            coreDataHelper.delete(
                entity: .attribute,
                by: "userKey",
                values: [encUserKey])
            return
        }

        if let entity = getByUserKey(encUserKey) ??
            coreDataHelper.create(entity: .attribute) as? AttributeEntity {
            entity.userKey = encUserKey
            do {
                let json = try Json.dynamicEncodeToJson(AttributeMap(attributes: attributes))
                entity.attributes = cipher?.encrypt(json) ?? json
            } catch {
                Logger.e("Error while parsing attributes to store them in DB: \(error)")
            }
            coreDataHelper.save()
        }
    }

    private func getByUserKey(_ userKey: String) -> AttributeEntity? {
        let predicate = NSPredicate(format: "userKey == %@", userKey)
        let entities = coreDataHelper.fetch(
            entity: .attribute,
            where: predicate).compactMap { $0 as? AttributeEntity }
        if !entities.isEmpty {
            return entities[0]
        }
        return nil
    }

    private func mapEntityToModel(_ entity: AttributeEntity) -> [String: Any]? {
        do {
            if let attributes = entity.attributes {
                let json = cipher?.decrypt(attributes) ?? attributes
                let attributeMap = try Json.dynamicDecodeFrom(json: json, to: AttributeMap.self)
                return attributeMap.attributes
            }
        } catch {
            Logger.e("Something happened when loading attributes from cache: \(error)")
        }
        return nil
    }
}
