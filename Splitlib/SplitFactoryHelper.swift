//
//  SplitFactoryHelper.swift
//  Splitlib
//
//  Created by Javier Avrudsky on 19-Oct-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

struct SplitFactoryHelper {
    static private let kDbMagicCharsCount = 4
    static private let kDbExt = ["", "-shm", "-wal"]

    static func buildStorageContainer(userKey: String,
                                      databaseName: String,
                                      testDatabase: SplitDatabase?) throws -> SplitStorageContainer {

        let fileStorage = FileStorage(dataFolderName: databaseName)
        let splitDatabase = try openDatabase(dataFolderName: databaseName, testDatabase: testDatabase)

        let persistentSplitsStorage = DefaultPersistentSplitsStorage(database: splitDatabase)
        let splitsStorage = openSplitsStorage(database: splitDatabase)
        let mySegmentsStorage = openMySegmentsStorage(database: splitDatabase, userKey: userKey)
        let impressionsStorage = openImpressionsStorage(database: splitDatabase)
        let impressionsCountStorage = openImpressionsCountStorage(database: splitDatabase)
        let eventsStorage = openEventsStorage(database: splitDatabase)
        return SplitStorageContainer(splitDatabase: splitDatabase,
                                     fileStorage: fileStorage,
                                     splitsStorage: splitsStorage,
                                     persistentSplitsStorage: persistentSplitsStorage,
                                     mySegmentsStorage: mySegmentsStorage,
                                     impressionsStorage: impressionsStorage,
                                     impressionsCountStorage: impressionsCountStorage,
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

    static func openPersistentMySegmentsStorage(database: SplitDatabase,
                                                userKey: String) -> PersistentMySegmentsStorage {
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

    static func openImpressionsCountStorage(database: SplitDatabase) -> PersistentImpressionsCountStorage {
        return DefaultImpressionsCountStorage(database: database,
                                         expirationPeriod: ServiceConstants.recordedDataExpirationPeriodInSeconds)
    }

    static func openEventsStorage(database: SplitDatabase) -> PersistentEventsStorage {
        return DefaultEventsStorage(database: database,
                                         expirationPeriod: ServiceConstants.recordedDataExpirationPeriodInSeconds)
    }

    static func databaseName(apiKey: String) -> String? {
        if apiKey.count < kDbMagicCharsCount {
            return nil
        }
        return "\(apiKey.prefix(kDbMagicCharsCount))\(apiKey.suffix(kDbMagicCharsCount))"
    }

    static func renameDatabaseFromLegacyName(name dbName: String, apiKey: String) {
    }

    static func sanitizeForFolderName(_ string: String) -> String {
        guard let regex: NSRegularExpression =
            try? NSRegularExpression(pattern: "[^a-zA-Z0-9]",
                                     options: NSRegularExpression.Options.caseInsensitive) else {
                fatalError("Regular expression not valid")
        }
        let range = NSRange(location: 0, length: string.count)
        return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
    }
}

