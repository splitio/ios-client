//
//  EventDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import CoreData

protocol SplitDao {
    func insertOrUpdate(splits: [SplitDTO])
    func insertOrUpdate(split: SplitDTO)
    func getAll() -> [SplitDTO]
    func delete(_ splits: [String])
    func deleteAll()
    func syncInsertOrUpdate(split: SplitDTO)
}

class CoreDataSplitDao: BaseCoreDataDao, SplitDao {
    private let decoder: SplitsDecoder
    private let encoder: SplitsEncoder
    private var cipher: Cipher?

    init(coreDataHelper: CoreDataHelper, cipher: Cipher? = nil) {
        self.decoder = SplitsParallelDecoder(cipher: cipher)
        self.encoder = SplitsParallelEncoder(cipher: cipher)
        self.cipher = cipher
        super.init(coreDataHelper: coreDataHelper)
    }

    func insertOrUpdate(splits: [SplitDTO]) {
        let parsed = self.encoder.encode(splits)
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            parsed.forEach { name, json in
                if let obj = self.getBy(name: name) ?? self.coreDataHelper.create(entity: .split) as? SplitEntity {
                    obj.name = name
                    obj.body = json
                    obj.updatedAt = Date.now()
                    // Saving one by one to avoid losing all
                    // if an error occurs
                    self.coreDataHelper.save()
                }
            }
        }
    }

    func insertOrUpdate(split: SplitDTO) {
        executeAsync { [weak self] in
            if let self = self {
                self.insertOrUpdate(split)
            }
        }
    }

    // For testing purposes only
    func syncInsertOrUpdate(split: SplitDTO) {
        execute { [weak self] in
            if let self = self {
                self.insertOrUpdate(split)
            }
        }
    }

    func getAll() -> [SplitDTO] {

        var splits: [SplitDTO]?
        execute { [weak self] in
            let start = Date.nowMillis()
            guard let self = self else {
                return
            }

            let jsonSplits = self.coreDataHelper.fetch(entity: .split)
                .compactMap { return $0 as? SplitEntity }
                .compactMap { return $0.body }
            TimeChecker.logInterval("Time to load feature flags", startTime: start)
            splits = self.decoder.decode(jsonSplits).map { $0 }
        }
        return splits ?? []
    }

    func delete(_ splits: [String]) {
        if splits.count == 0 {
            return
        }

        executeAsync { [weak self] in
            guard let self = self else {
                return
            }

            var names = splits
            if let cipher = self.cipher {
                names = splits.map { cipher.encrypt($0) ?? $0 }
            }
            self.coreDataHelper.delete(entity: .split, by: "name", values: names)
            self.coreDataHelper.save()
        }
    }

    func deleteAll() {
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.deleteAll(entity: .split)
        }
    }

    private func insertOrUpdate(_ split: SplitDTO) {
        if let splitName = cipher?.encrypt(split.name) ?? split.name,
           let obj = self.getBy(name: splitName) ?? self.coreDataHelper.create(entity: .split) as? SplitEntity {
            do {
                obj.name = splitName
                let json = try Json.encodeToJson(split)
                obj.body = cipher?.encrypt(json) ?? json
                obj.updatedAt = Date.now()
                // Saving one by one to avoid losing all
                // if an error occurs
                self.coreDataHelper.save()
            } catch {
                Logger.e("An error occurred while inserting feature flags in storage: \(error.localizedDescription)")
            }
        }
    }

    private func getBy(name: String) -> SplitEntity? {
        let predicate = NSPredicate(format: "name == %@", name)
        let entities = coreDataHelper.fetch(entity: .split,
                                            where: predicate).compactMap { return $0 as? SplitEntity }
        return entities.count > 0 ? entities[0] : nil
    }
}
