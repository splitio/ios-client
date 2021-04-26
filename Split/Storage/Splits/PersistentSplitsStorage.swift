//
//  PersistentSplitsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 10/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol PersistentSplitsStorage {
    func update(splitChange: ProcessedSplitChange)
    func update(split: Split)
    func update(filterQueryString: String)
    func getFilterQueryString() -> String
    func getSplitsSnapshot() -> SplitsSnapshot
    func getChangeNumber() -> Int64
    func getUpdateTimestamp() -> Int64
    func getAll() -> [Split]
    func delete(splitNames: [String])
    func clear()
}

class DefaultPersistentSplitsStorage: PersistentSplitsStorage {

    private let splitDao: SplitDao
    private let generalInfoDao: GeneralInfoDao

    init(database: SplitDatabase) {
        self.splitDao = database.splitDao
        self.generalInfoDao = database.generalInfoDao
    }

    func update(splitChange: ProcessedSplitChange) {
        splitDao.insertOrUpdate(splits: splitChange.activeSplits)
        splitDao.delete(splitChange.archivedSplits.compactMap { return $0.name })
        generalInfoDao.update(info: .splitsChangeNumber, longValue: splitChange.changeNumber)
        generalInfoDao.update(info: .splitsUpdateTimestamp, longValue: splitChange.updateTimestamp)
    }

    func update(split: Split) {
        splitDao.insertOrUpdate(split: split)
    }

    func update(filterQueryString: String) {
        generalInfoDao.update(info: .splitsFilterQueryString, stringValue: filterQueryString)
    }

    func getFilterQueryString() -> String {
        return generalInfoDao.stringValue(info: .splitsFilterQueryString) ?? ""
    }

    func getSplitsSnapshot() -> SplitsSnapshot {
        return SplitsSnapshot(changeNumber: generalInfoDao.longValue(info: .splitsChangeNumber) ?? -1,
                              splits: splitDao.getAll(),
                              updateTimestamp: generalInfoDao.longValue(info: .splitsUpdateTimestamp) ?? 0,
                              splitsFilterQueryString: getFilterQueryString())
    }

    func getChangeNumber() -> Int64 {
        return generalInfoDao.longValue(info: .splitsChangeNumber) ?? -1
    }

    func getUpdateTimestamp() -> Int64 {
        return generalInfoDao.longValue(info: .splitsUpdateTimestamp) ?? 0
    }

    func getAll() -> [Split] {
        return splitDao.getAll()
    }

    func delete(splitNames: [String]) {
        splitDao.delete(splitNames)
    }

    func clear() {
        generalInfoDao.update(info: .splitsChangeNumber, longValue: -1)
        splitDao.deleteAll()
    }
}
