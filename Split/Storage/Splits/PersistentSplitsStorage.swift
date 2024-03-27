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
    func update(split: SplitDTO)
    func update(filterQueryString: String)
    func update(bySetsFilter: SplitFilter?)
    func getFilterQueryString() -> String
    func getBySetsFilter() -> SplitFilter?
    func getSplitsSnapshot() -> SplitsSnapshot
    func getChangeNumber() -> Int64
    func getUpdateTimestamp() -> Int64
    func getAll() -> [SplitDTO]
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

    func update(split: SplitDTO) {
        splitDao.insertOrUpdate(split: split)
    }

    func update(filterQueryString: String) {
        generalInfoDao.update(info: .splitsFilterQueryString, stringValue: filterQueryString)
    }

    func getFilterQueryString() -> String {
        return generalInfoDao.stringValue(info: .splitsFilterQueryString) ?? ""
    }

    func update(bySetsFilter filter: SplitFilter?) {
        guard let filter = filter else {
            generalInfoDao.delete(info: .bySetsFilter)
            return
        }

        do {
            generalInfoDao.update(info: .bySetsFilter, stringValue: try Json.encodeToJson(filter))
        } catch {
            Logger.e("Could not encode By Sets filter to store in cache. Error: \(error.localizedDescription)")
            return
        }
    }

    func getBySetsFilter() -> SplitFilter? {

        guard let filterString = generalInfoDao.stringValue(info: .bySetsFilter) else {
            return nil
        }

        do {
            return try Json.decodeFrom(json: filterString, to: SplitFilter.self)
        } catch {
            Logger.e("Could not decode stored by Sets split filter. Error: \(error.localizedDescription)")
        }
        return nil
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

    func getAll() -> [SplitDTO] {
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
