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

        let splitDatabase = try openDatabase(dataFolderName: dataFolderName, testDatabase: testDatabase)

        let persistentSplitsStorage = DefaultPersistentSplitsStorage(database: splitDatabase)
        let splitsStorage = openSplitsStorage(database: splitDatabase)
        let mySegmentsStorage = openMySegmentsStorage(database: splitDatabase, userKey: userKey)
        let impressionsStorage = openImpressionsStorage(database: splitDatabase)
        let eventsStorage = openEventsStorage(database: splitDatabase)
        return SplitStorageContainer(splitDatabase: splitDatabase,
                                     fileStorage: fileStorage,
                                     splitsStorage: splitsStorage,
                                     persistentSplitsStorage: persistentSplitsStorage,
                                     mySegmentsStorage: mySegmentsStorage,
                                     impressionsStorage: impressionsStorage,
                                     eventsStorage: eventsStorage)
    }

    static func openDatabase(dataFolderName: String,
                             testDatabase: SplitDatabase? = nil) throws -> SplitDatabase {

        if let database = testDatabase {
            return database
        }


        guard let helper = CoreDataHelperBuilder.build(databaseName: dataFolderName) else {
            throw GenericError.couldNotCreateCache
        }
        return CoreDataSplitDatabase(coreDataHelper: helper)
    }

    static func openPersistentSplitsStorage(database: SplitDatabase) -> PersistentSplitsStorage {
        return DefaultPersistentSplitsStorage(database: database)
    }

    static func openSplitsStorage(database: SplitDatabase) -> SplitsStorage {
        return DefaultSplitsStorage(persistentSplitsStorage: openPersistentSplitsStorage(database: database))
    }

    static func openPersistentMySegmentsStorage(database: SplitDatabase, userKey: String) -> PersistentMySegmentsStorage {
        return DefaultPersistentMySegmentsStorage(userKey: userKey, database: database)
    }

    static func openMySegmentsStorage(database: SplitDatabase, userKey: String) -> MySegmentsStorage {
        let persistentMySegmentsStorage = openPersistentMySegmentsStorage(database: database, userKey: userKey)
        return DefaultMySegmentsStorage(persistentMySegmentsStorage: persistentMySegmentsStorage)
    }

    static func openImpressionsStorage(database: SplitDatabase) -> PersistentImpressionsStorage {
        return DefaultImpressionsStorage(database: database,
                                         expirationPeriod: ServiceConstants.recordedDataExpirationPeriodInSeconds)
    }

    static func openEventsStorage(database: SplitDatabase) -> PersistentEventsStorage {
        return DefaultEventsStorage(database: database,
                                         expirationPeriod: ServiceConstants.recordedDataExpirationPeriodInSeconds)
    }
}
