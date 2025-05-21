//
//  RuleBasedSegmentDao.swift
//  Split
//
//  Created by Split on 14/03/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation
import CoreData

protocol RuleBasedSegmentDao {
    func insertOrUpdate(segments: [RuleBasedSegment])
    func insertOrUpdate(segment: RuleBasedSegment)
    func getAll() -> [RuleBasedSegment]
    func delete(_ segments: [String])
    func deleteAll()
    func syncInsertOrUpdate(segment: RuleBasedSegment)
}

class CoreDataRuleBasedSegmentDao: BaseCoreDataDao, RuleBasedSegmentDao {
    private let decoder: RuleBasedSegmentsDecoder
    private let encoder: RuleBasedSegmentsEncoder
    private var cipher: Cipher?

    init(coreDataHelper: CoreDataHelper, cipher: Cipher? = nil) {
        self.decoder = RuleBasedSegmentsSerialDecoder(cipher: cipher)
        self.encoder = RuleBasedSegmentsSerialEncoder(cipher: cipher)
        self.cipher = cipher
        super.init(coreDataHelper: coreDataHelper)
    }

    func insertOrUpdate(segments: [RuleBasedSegment]) {
        let parsed = self.encoder.encode(segments)
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            parsed.forEach { name, json in
                if let obj = self.getBy(name: name) ?? self.coreDataHelper.create(entity: .ruleBasedSegment) as? RuleBasedSegmentEntity {
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

    func insertOrUpdate(segment: RuleBasedSegment) {
        executeAsync { [weak self] in
            if let self = self {
                self.insertOrUpdate(segment)
            }
        }
    }

    // For testing purposes only
    func syncInsertOrUpdate(segment: RuleBasedSegment) {
        execute { [weak self] in
            if let self = self {
                self.insertOrUpdate(segment)
            }
        }
    }

    func getAll() -> [RuleBasedSegment] {
        var segments: [RuleBasedSegment]?
        execute { [weak self] in
            let start = Date.nowMillis()
            guard let self = self else {
                return
            }

            let jsonSegments = self.coreDataHelper.fetch(entity: .ruleBasedSegment)
                .compactMap { return $0 as? RuleBasedSegmentEntity }
                .compactMap { return $0.body }
            TimeChecker.logInterval("Time to load rule based segments", startTime: start)
            segments = self.decoder.decode(jsonSegments).map { $0 }
        }
        return segments ?? []
    }

    func delete(_ segments: [String]) {
        if segments.count == 0 {
            return
        }

        executeAsync { [weak self] in
            guard let self = self else {
                return
            }

            var names = segments
            if let cipher = self.cipher {
                names = segments.map { cipher.encrypt($0) ?? $0 }
            }
            self.coreDataHelper.delete(entity: .ruleBasedSegment, by: "name", values: names)
            self.coreDataHelper.save()
        }
    }

    func deleteAll() {
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.coreDataHelper.deleteAll(entity: .ruleBasedSegment)
        }
    }

    private func insertOrUpdate(_ segment: RuleBasedSegment) {
        if let segmentName = cipher?.encrypt(segment.name) ?? segment.name,
           let obj = self.getBy(name: segmentName) ?? self.coreDataHelper.create(entity: .ruleBasedSegment) as? RuleBasedSegmentEntity {
            do {
                obj.name = segmentName
                let json = try Json.encodeToJson(segment)
                obj.body = cipher?.encrypt(json) ?? json
                obj.updatedAt = Date.now()
                // Saving one by one to avoid losing all
                // if an error occurs
                self.coreDataHelper.save()
            } catch {
                Logger.e("An error occurred while inserting rule based segments in storage: \(error.localizedDescription)")
            }
        }
    }

    private func getBy(name: String) -> RuleBasedSegmentEntity? {
        let predicate = NSPredicate(format: "name == %@", name)
        let entities = coreDataHelper.fetch(entity: .ruleBasedSegment,
                                          where: predicate).compactMap { return $0 as? RuleBasedSegmentEntity }
        return entities.count > 0 ? entities[0] : nil
    }
}
