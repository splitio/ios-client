//
//  SplitFactoryHelper.swift
//  Split
//
//  Created by Javier Avrudsky on 16/03/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

struct SplitDatabaseHelper {
    static private let kDbMagicCharsCount = 4
    static private let kDbExt = ["", "-shm", "-wal"]
    static private let kExpirationPeriod = ServiceConstants.recordedDataExpirationPeriodInSeconds

    static func currentEncryptionLevel() -> SplitEncryptionLevel {
        return GlobalSecureStorage.shared.get(item: .dbEncryptionLevel,
                                              type: SplitEncryptionLevel.self) ?? .none
    }

    static func setCurrentEncryptionLevel(_ level: SplitEncryptionLevel) {
        GlobalSecureStorage.shared.set(item: level, for: .dbEncryptionLevel)
    }

    static func buildStorageContainer(splitClientConfig: SplitClientConfig,
                                      apiKey: String,
                                      userKey: String,
                                      databaseName: String,
                                      telemetryStorage: TelemetryStorage?,
                                      testDatabase: SplitDatabase?) throws -> SplitStorageContainer {

        let curEncryptionLevel = currentEncryptionLevel()
        var splitDatabase = testDatabase
        var dbHelper: CoreDataHelper?
        if let testDb = testDatabase as? TestSplitDatabase {
            dbHelper = testDb.coreDataHelper
        } else {
            dbHelper = CoreDataHelperBuilder.build(databaseName: databaseName)
        }

        guard let dbHelper = dbHelper else {
            Logger.e("Error creating database helper")
            throw GenericError.couldNotCreateCache
        }

        if currentEncryptionLevel() != splitClientConfig.dbEncryptionLevel {
            let dbCipher = try DbCipher(apiKey: apiKey,
                                        from: curEncryptionLevel,
                                        to: splitClientConfig.dbEncryptionLevel,
                                        coreDataHelper: dbHelper)
            dbCipher.apply()
            setCurrentEncryptionLevel(splitClientConfig.dbEncryptionLevel)

        }

        if splitDatabase == nil {
            splitDatabase = try openDatabase(dataFolderName: databaseName,
                                          apiKey: apiKey,
                                          encryptionLevel: splitClientConfig.dbEncryptionLevel,
                                          dbHelper: dbHelper)
        }

        guard let splitDatabase = splitDatabase else {
            Logger.e("Error opening database")
            throw GenericError.couldNotCreateCache
        }

        let persistentSplitsStorage = DefaultPersistentSplitsStorage(database: splitDatabase)
        let splitsStorage = openSplitsStorage(database: splitDatabase)

        let persistentImpressionsStorage = openPersistentImpressionsStorage(database: splitDatabase)
        let impressionsStorage = openImpressionsStorage(persistentStorage: persistentImpressionsStorage)
        let impressionsCountStorage = openImpressionsCountStorage(database: splitDatabase)

        let persistentEventsStorage = openPersistentEventsStorage(database: splitDatabase)
        let eventsStorage = openEventsStorage(persistentStorage: persistentEventsStorage)

        let mySegmentsStorage = openMySegmentsStorage(database: splitDatabase)
        let attributesStorage = openAttributesStorage(database: splitDatabase,
                                                      splitClientConfig: splitClientConfig)

        var uniqueKeyStorage: PersistentUniqueKeysStorage?
        if splitClientConfig.$impressionsMode == .none {
            uniqueKeyStorage =
            DefaultPersistentUniqueKeysStorage(database: splitDatabase,
                                               expirationPeriod: kExpirationPeriod)
        }

        return SplitStorageContainer(splitDatabase: splitDatabase,
                                     splitsStorage: splitsStorage,
                                     persistentSplitsStorage: persistentSplitsStorage,
                                     impressionsStorage: impressionsStorage,
                                     persistentImpressionsStorage: persistentImpressionsStorage,
                                     impressionsCountStorage: impressionsCountStorage,
                                     eventsStorage: eventsStorage,
                                     persistentEventsStorage: persistentEventsStorage,
                                     telemetryStorage: telemetryStorage,
                                     mySegmentsStorage: mySegmentsStorage,
                                     attributesStorage: attributesStorage,
                                     uniqueKeyStorage: uniqueKeyStorage)
    }

    static func openDatabase(dataFolderName: String,
                             apiKey: String,
                             encryptionLevel: SplitEncryptionLevel,
                             dbHelper: CoreDataHelper) throws -> SplitDatabase {

        return CoreDataSplitDatabase(coreDataHelper: dbHelper,
                                     cipher: createCipher(level: encryptionLevel,
                                                          apiKey: apiKey))
    }

    static func openPersistentSplitsStorage(database: SplitDatabase) -> PersistentSplitsStorage {
        return DefaultPersistentSplitsStorage(database: database)
    }

    static func openSplitsStorage(database: SplitDatabase) -> SplitsStorage {
        return DefaultSplitsStorage(persistentSplitsStorage: openPersistentSplitsStorage(database: database))
    }

    static func openPersistentMySegmentsStorage(database: SplitDatabase) -> PersistentMySegmentsStorage {
        return DefaultPersistentMySegmentsStorage(database: database)
    }

    static func openMySegmentsStorage(database: SplitDatabase) -> MySegmentsStorage {
        let persistentMySegmentsStorage = openPersistentMySegmentsStorage(database: database)
        return DefaultMySegmentsStorage(persistentMySegmentsStorage: persistentMySegmentsStorage)
    }

    static func openPersistentAttributesStorage(database: SplitDatabase) -> PersistentAttributesStorage {
        return DefaultPersistentAttributesStorage(database: database)
    }

    static func openAttributesStorage(database: SplitDatabase,
                                      splitClientConfig: SplitClientConfig) -> AttributesStorage {
        return DefaultAttributesStorage(
            persistentAttributesStorage: splitClientConfig.persistentAttributesEnabled ?
            openPersistentAttributesStorage(database: database) : nil
        )
    }

    static func openPersistentImpressionsStorage(database: SplitDatabase) -> PersistentImpressionsStorage {
        return DefaultImpressionsStorage(database: database,
                                         expirationPeriod: ServiceConstants.recordedDataExpirationPeriodInSeconds)
    }

    static func openImpressionsStorage(persistentStorage: PersistentImpressionsStorage) -> ImpressionsStorage {
        return MainImpressionsStorage(persistentStorage: persistentStorage)
    }

    static func openImpressionsCountStorage(database: SplitDatabase) -> PersistentImpressionsCountStorage {
        return DefaultImpressionsCountStorage(database: database,
                                              expirationPeriod: ServiceConstants.recordedDataExpirationPeriodInSeconds)
    }

    static func openPersistentEventsStorage(database: SplitDatabase) -> PersistentEventsStorage {
        return DefaultEventsStorage(database: database,
                                    expirationPeriod: ServiceConstants.recordedDataExpirationPeriodInSeconds)
    }

    static func openEventsStorage(persistentStorage: PersistentEventsStorage) -> EventsStorage {
        return MainEventsStorage(persistentStorage: persistentStorage)
    }

    static func databaseName(apiKey: String) -> String? {
        if apiKey.count < kDbMagicCharsCount * 2 {
            return nil
        }
        return "\(apiKey.prefix(kDbMagicCharsCount))\(apiKey.suffix(kDbMagicCharsCount))"
    }

    static func sanitizeForFolderName(_ string: String) -> String {
        guard let regex: NSRegularExpression =
                try? NSRegularExpression(pattern: "[^a-zA-Z0-9]",
                                         options: NSRegularExpression.Options.caseInsensitive) else {
            Logger.d("sanitizeForFolderName: Regular expression not valid")
            return "dummyName"
        }
        let range = NSRange(location: 0, length: string.count)
        return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
    }

    static func createByKeyMySegmentsStorage(mySegmentsStorage: MySegmentsStorage,
                                             userKey: String) -> ByKeyMySegmentsStorage {
        return DefaultByKeyMySegmentsStorage(mySegmentsStorage: mySegmentsStorage, userKey: userKey)
    }

    static func createCipher(level: SplitEncryptionLevel, apiKey: String) -> Cipher? {
        if level == .none {
            return nil
        }
        return DefaultCipher(key: apiKey)
    }
}
