//
//  GeneralInfoDao.swift
//  Split
//
//  Created by Javier Avrudsky on 25/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

enum GeneralInfo: String {
    case splitsUpdateTimestamp = "splitsUpdateTimestamp"
    case splitsChangeNumber = "splitChangeNumber"
    case splitsFilterQueryString = "splitsFilterQueryString"
    case databaseMigrationStatus = "databaseMigrationStatus"
}

protocol GeneralInfoDao {
    func update(info: GeneralInfo, stringValue: String)
    func update(info: GeneralInfo, longValue: Int64)
    func stringValue(info: GeneralInfo) -> String?
    func longValue(info: GeneralInfo) -> Int64?
}

class CoreDataGeneralInfoDao: BaseCoreDataDao, GeneralInfoDao {

    func update(info: GeneralInfo, stringValue: String) {
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.update(info: info, stringValue: stringValue, longValue: nil)
        }
    }

    func update(info: GeneralInfo, longValue: Int64) {
        executeAsync { [weak self] in
            guard let self = self else {
                return
            }
            self.update(info: info, stringValue: "", longValue: longValue)
        }
    }

    func stringValue(info: GeneralInfo) -> String? {
        var value: String?
        execute { [weak self] in
            guard let self = self else {
                return
            }
            if let infoValue = self.get(for: info) {
                value = infoValue.stringValue
            }
        }
        return value
    }

    func longValue(info: GeneralInfo) -> Int64? {
        var value: Int64?
        execute { [weak self] in
            guard let self = self else {
                return
            }
            if let infoValue = self.get(for: info) {
                value = infoValue.longValue
            }
        }
        return value
    }

    private func update(info: GeneralInfo, stringValue: String?, longValue: Int64?) {
        if let obj = get(for: info) ?? coreDataHelper.create(entity: .generalInfo) as? GeneralInfoEntity {
            obj.name = info.rawValue
            obj.stringValue = stringValue ?? ""
            obj.longValue = longValue ?? 0
            obj.updatedAt = Date().unixTimestamp()
            coreDataHelper.save()
        }
    }

    private func get(for info: GeneralInfo) -> GeneralInfoEntity? {
        let predicate = NSPredicate(format: "name == %@", info.rawValue)
        let entities = coreDataHelper.fetch(entity: .generalInfo,
                                            where: predicate).compactMap { return $0 as? GeneralInfoEntity }
        return entities.count > 0 ? entities[0] : nil
    }
}
