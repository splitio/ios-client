//
//  PersistentSplitsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 10/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol PersistentSplitsStorage {
    func update(splitChange: ProcessedSplitChange, onFailure: ((Error) -> Void)?)
    func update(split: Split)
    func update(bySetsFilter: SplitFilter?)
    func getBySetsFilter() -> SplitFilter?
    func getSplitsSnapshot() -> SplitsSnapshot
    func getChangeNumber() -> Int64
    func getUpdateTimestamp() -> Int64
    func getAll() -> [Split]
    func delete(splitNames: [String])
    func clear()
}

class DefaultPersistentSplitsStorage: PersistentSplitsStorage, @unchecked Sendable {

    private let splitDao: SplitDao
    private let generalInfoDao: GeneralInfoDao
    private let coreDataHelper: CoreDataHelper

    init(database: SplitDatabase) {
        self.splitDao = database.splitDao
        self.generalInfoDao = database.generalInfoDao
        if let testDb = database as? TestSplitDatabase {
            self.coreDataHelper = testDb.coreDataHelper
        } else {
            fatalError("Database must provide CoreDataHelper for transactional operations")
        }
    }

    func update(splitChange: ProcessedSplitChange, onFailure: ((Error) -> Void)? = nil) {
        // This is intentionally async to avoid blocking the caller thread.
        // All operations must succeed or all must fail.
        coreDataHelper.perform { [weak self] in
            guard let self = self else { return }
            
            do {
                // All operations within this block happen in the same CoreData context
                self.splitDao.transactionalInsertOrUpdate(splits: splitChange.activeSplits)
                let archivedNames = splitChange.archivedSplits.compactMap { $0.name }
                self.splitDao.transactionalDelete(archivedNames)
                
                self.generalInfoDao.transactionalUpdate(info: .splitsChangeNumber, longValue: splitChange.changeNumber)
                self.generalInfoDao.transactionalUpdate(info: .splitsUpdateTimestamp, longValue: splitChange.updateTimestamp)
                
                // Save everything as one transaction
                try self.coreDataHelper.saveWithErrorHandling()
            } catch {
                Logger.e("Transactional flags update failed: \(error.localizedDescription)")
                // Rollback to avoid leaving invalid pending changes in the shared context,
                self.coreDataHelper.rollback()
                onFailure?(error)
            }
        }
    }

    func update(split: Split) {
        splitDao.insertOrUpdate(split: split)
    }

    func update(filterQueryString: String) {
        generalInfoDao.update(info: .splitsFilterQueryString, stringValue: filterQueryString)
    }

    func update(flagsSpec: String) {
        generalInfoDao.update(info: .flagsSpec, stringValue: flagsSpec)
    }

    func getFilterQueryString() -> String {
        return generalInfoDao.stringValue(info: .splitsFilterQueryString) ?? ""
    }

    func getFlagsSpec() -> String {
        return generalInfoDao.stringValue(info: .flagsSpec) ?? ""
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
                              updateTimestamp: generalInfoDao.longValue(info: .splitsUpdateTimestamp) ?? 0)
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
