//
//  EventDao.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import CoreData
import Foundation

protocol SplitDao {
    func insertOrUpdate(splits: [Split])
    func insertOrUpdate(split: Split)
    func getAll() -> [Split]
    func delete(_ splits: [String])
    func deleteAll()
    func syncInsertOrUpdate(split: Split)
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

    func insertOrUpdate(splits: [Split]) {
        let parsed = encoder.encode(splits)
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

    func insertOrUpdate(split: Split) {
        executeAsync { [weak self] in
            if let self = self {
                self.insertOrUpdate(split)
            }
        }
    }

    // For testing purposes only
    func syncInsertOrUpdate(split: Split) {
        execute { [weak self] in
            if let self = self {
                self.insertOrUpdate(split)
            }
        }
    }

    func getAll() -> [Split] {
        var splits: [Split]?
        execute { [weak self] in
            let start = Date.nowMillis()
            guard let self = self else {
                return
            }

            let jsonSplits = self.coreDataHelper.fetch(entity: .split)
                .compactMap { $0 as? SplitEntity }
                .compactMap { $0.body }
            TimeChecker.logInterval("Time to load feature flags", startTime: start)
            splits = self.decoder.decode(jsonSplits).map { $0 }
        }
        return splits ?? []
    }

    func delete(_ splits: [String]) {
        if splits.isEmpty {
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

    private func insertOrUpdate(_ split: Split) {
        if let splitName = cipher?.encrypt(split.name) ?? split.name,
           let obj = getBy(name: splitName) ?? coreDataHelper.create(entity: .split) as? SplitEntity {
            do {
                obj.name = splitName
                let json = try Json.encodeToJson(split)
                obj.body = cipher?.encrypt(json) ?? json
                obj.updatedAt = Date.now()
                // Saving one by one to avoid losing all
                // if an error occurs
                coreDataHelper.save()
            } catch {
                Logger.e("An error occurred while inserting feature flags in storage: \(error.localizedDescription)")
            }
        }
    }

    private func getBy(name: String) -> SplitEntity? {
        let predicate = NSPredicate(format: "name == %@", name)
        let entities = coreDataHelper.fetch(
            entity: .split,
            where: predicate).compactMap { $0 as? SplitEntity }
        return !entities.isEmpty ? entities[0] : nil
    }
}
