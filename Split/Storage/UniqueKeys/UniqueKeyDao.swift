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
    func getBy(userKey: String) -> [String]
    func update(userKey: String, featureList: [String])
}

class CoreDataUniqueKeyDao: BaseCoreDataDao, UniqueKeyDao {

    func getBy(userKey: String) -> [String] {
        var uniqueKeys = [String]()
        execute { [weak self] in
            guard let self = self else {
                return
            }

            if let entity = self.getByUserKey(userKey) {
                uniqueKeys.append(contentsOf: self.mapEntityToModel(entity))
            }
        }
        return uniqueKeys
    }

    func update(userKey: String, featureList: [String]) {

        executeAsync { [weak self] in
            guard let self = self else {
                return
            }

            if let entity = self.getByUserKey(userKey) ??
                self.coreDataHelper.create(entity: .uniqueKey) as? UniqueKeyEntity {
                do {
                    entity.userKey = userKey
                    entity.featureList = try Json.encodeToJson(featureList)
                    self.coreDataHelper.save()
                } catch {
                    Logger.d("Could not parse unique keys to store in cache")
                }
            }
        }
    }

    private func getByUserKey(_ userKey: String) -> UniqueKeyEntity? {
        let predicate = NSPredicate(format: "userKey == %@", userKey)
        let entities = self.coreDataHelper.fetch(entity: .uniqueKey,
                                                 where: predicate).compactMap { return $0 as? UniqueKeyEntity }
        if entities.count > 0 {
            return entities[0]
        }
        return nil
    }

    private func mapEntityToModel(_ entity: UniqueKeyEntity) -> [String] {
        if let parsedfeatureList = entity.featureList?.split(separator: ",") {
            return parsedfeatureList.map { String($0) }
        }
        guard let  featureList = entity.featureList else { return [] }

        return (try? Json.encodeFrom(json: featureList, to: [String].self)) ?? []
    }
}
