//
//  SplitFactoryHelper.swift
//  Split
//
//  Created by Javier Avrudsky on 16/03/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

struct SplitFactoryHelper {
    static func buildStorageContainer(userKey: String,
                                      dataFolderName: String,
                                      testDatabase: SplitDatabase?) throws -> SplitStorageContainer {
        let fileStorage = FileStorage(dataFolderName: dataFolderName)
        let dispatchQueue = DispatchQueue(label: "SplitCoreDataCache", target: DispatchQueue.global())
        var database: SplitDatabase?

        if testDatabase == nil {
            guard let helper = CoreDataHelperBuilder.build(databaseName: dataFolderName,
                                                           dispatchQueue: dispatchQueue) else {
                throw GenericError.coultNotCreateCache
            }
            database = CoreDataSplitDatabase(coreDataHelper: helper, dispatchQueue: dispatchQueue)
        } else {
            database = testDatabase
        }

        guard let splitDatabase = database else {
            throw GenericError.coultNotCreateCache
        }

        let persistentSplitsStorage = DefaultPersistentSplitsStorage(database: splitDatabase)
        let splitsStorage = DefaultSplitsStorage(persistentSplitsStorage: persistentSplitsStorage)

        let persistentMySegmentsStorage = DefaultPersistentMySegmentsStorage(userKey: userKey, database: splitDatabase)
        let mySegmentsStorage = DefaultMySegmentsStorage(persistentMySegmentsStorage: persistentMySegmentsStorage)

        let impressionsStorage
            = DefaultImpressionsStorage(database: splitDatabase,
                                        expirationPeriod: ServiceConstants.recordedDataExpirationPeriodInSeconds)

        let eventsStorage
            = DefaultEventsStorage(database: splitDatabase,
                                   expirationPeriod: ServiceConstants.recordedDataExpirationPeriodInSeconds)

        return SplitStorageContainer(splitDatabase: splitDatabase,
                                     fileStorage: fileStorage,
                                     splitsStorage: splitsStorage,
                                     persistentSplitsStorage: persistentSplitsStorage,
                                     mySegmentsStorage: mySegmentsStorage,
                                     impressionsStorage: impressionsStorage,
                                     eventsStorage: eventsStorage)
    }
}
