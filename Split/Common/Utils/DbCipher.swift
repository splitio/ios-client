//
//  DbCipher.swift
//  Split
//
//  Created by Javier Avrudsky on 27-Mar-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
import CoreData

struct DbCipher {

    private let dbHelper: CoreDataHelper
    private var fromCipher: Cipher?
    private var toCipher: Cipher?
    private var mustApply: Bool

    init(cipherKey: Data,
         from fromLevel: SplitEncryptionLevel,
         to toLevel: SplitEncryptionLevel,
         coreDataHelper: CoreDataHelper) throws {

        self.mustApply = fromLevel != toLevel
        if !mustApply {
            throw GenericError.noCipheringNeeded
        }

        self.dbHelper = coreDataHelper
        self.fromCipher = createCipher(cipherKey: cipherKey, level: fromLevel)
        self.toCipher = createCipher(cipherKey: cipherKey, level: toLevel)
        if fromCipher == nil, toCipher == nil {
            Logger.v("Something happend when encrypting / decrypting cache")
            mustApply = false
            throw GenericError.couldNotCreateCiphers
        }
    }

    func apply() {
        if !mustApply {
            return
        }
        dbHelper.performAndWait {
            updateSplits()
            updateRuleBasedSegments()
            updateSegments(type: .mySegment)
            updateSegments(type: .myLargeSegment)
            updateImpressions()
            updateUniqueKeys()
            updateAttributes()
            update(entity: .event)
            update(entity: .impressionsCount)
        }
        dbHelper.save()
    }

    private func updateSplits() {
        let items = dbHelper.fetch(entity: .split).compactMap { return $0 as? SplitEntity }
        for item in items {
            let name = fromCipher?.decrypt(item.name) ?? item.name
            item.name = toCipher?.encrypt(name) ?? name

            let body = fromCipher?.decrypt(item.body) ?? item.body
            item.body = toCipher?.encrypt(body) ?? body
        }
    }

    private func updateRuleBasedSegments() {
        let items = dbHelper.fetch(entity: .ruleBasedSegment).compactMap { return $0 as? RuleBasedSegmentEntity }
        for item in items {
            let name = fromCipher?.decrypt(item.name) ?? item.name
            item.name = toCipher?.encrypt(name) ?? name

            let body = fromCipher?.decrypt(item.body) ?? item.body
            item.body = toCipher?.encrypt(body) ?? body
        }
    }

    private func updateSegments(type entity: CoreDataEntity) {
        let items = dbHelper.fetch(entity: entity).compactMap { return $0 as? MySegmentEntity }
        for item in items {
            let userKey = fromCipher?.decrypt(item.userKey) ?? item.userKey
            item.userKey = toCipher?.encrypt(userKey) ?? userKey

            let body = fromCipher?.decrypt(item.segmentList) ?? item.segmentList
            item.segmentList = toCipher?.encrypt(body) ?? body
        }
    }

    private func updateImpressions() {
        let items = dbHelper.fetch(entity: .impression).compactMap { return $0 as? ImpressionEntity }
        for item in items {
            let testName = fromCipher?.decrypt(item.testName) ?? item.testName
            item.testName = toCipher?.encrypt(testName) ?? testName

            let body = fromCipher?.decrypt(item.body) ?? item.body
            item.body = toCipher?.encrypt(body) ?? body
        }
    }

    private func updateUniqueKeys() {
        let items = dbHelper.fetch(entity: .uniqueKey).compactMap { return $0 as? UniqueKeyEntity }
        for item in items {
            let userKey = fromCipher?.decrypt(item.userKey) ?? item.userKey
            item.userKey = toCipher?.encrypt(userKey) ?? userKey

            let featureList = fromCipher?.decrypt(item.featureList) ?? item.featureList
            item.featureList = toCipher?.encrypt(featureList) ?? featureList
        }
    }

    private func updateAttributes() {
        let items = dbHelper.fetch(entity: .attribute).compactMap { return $0 as? AttributeEntity }
        for item in items {
            let userKey = fromCipher?.decrypt(item.userKey) ?? item.userKey
            item.userKey = toCipher?.encrypt(userKey) ?? userKey

            let attributes = fromCipher?.decrypt(item.attributes) ?? item.attributes
            item.attributes = toCipher?.encrypt(attributes) ?? attributes
        }
    }

    private func update(entity: CoreDataEntity) {
        let bodyField = "body"
        let items = dbHelper.fetch(entity: entity).compactMap { return $0 as? NSManagedObject }
        for item in items {
            guard let body = item.value(forKey: bodyField) as? String else {
                continue
            }
            let tempBody = fromCipher?.decrypt(body) ?? body
            item.setValue(toCipher?.encrypt(tempBody) ?? tempBody, forKey: bodyField)
        }
    }

    private func createCipher(cipherKey: Data, level: SplitEncryptionLevel) -> Cipher? {
        if level == .none {
            return nil
        }
        return DefaultCipher(cipherKey: cipherKey)
    }
}
