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


    static func buildStorageContainer(splitClientConfig: SplitClientConfig,
                                      apiKey: String,
                                      userKey: String,
                                      databaseName: String,
                                      telemetryStorage: TelemetryStorage?,
                                      testDatabase: SplitDatabase?) throws -> SplitStorageContainer {
        let dbKey = buildDbKey(prefix: splitClientConfig.prefix, sdkKey: apiKey)
        let previousEncryptionLevel = DbEncryptionManager.currentEncryptionLevel(dbKey: dbKey)
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
        let encryptionLevel: SplitEncryptionLevel = splitClientConfig.encryptionEnabled ? .aes128Cbc : .none
        var cipherKey: Data? = encryptionLevel != .none ? DbEncryptionManager.currentEncryptionKey(for: dbKey) : nil
        let generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: dbHelper)

        // Validate encryption key and recover if needed
        let validationResult = DbEncryptionManager.validateAndRecoverEncryptionKey(
            dbKey: dbKey, previousLevel: previousEncryptionLevel, targetLevel: encryptionLevel,
            currentKey: cipherKey, dbHelper: dbHelper, generalInfoDao: generalInfoDao)
        cipherKey = validationResult.cipherKey

        // Handle migration if recovery wasn't performed
        if !validationResult.recoveryPerformed {
            try DbEncryptionManager.handleEncryptionMigration(dbKey: dbKey, targetLevel: encryptionLevel,
                                          cipherKey: cipherKey, dbHelper: dbHelper,
                                          generalInfoDao: generalInfoDao)
        }

        if splitDatabase == nil {
            splitDatabase = try openDatabase(dataFolderName: databaseName,
                                             cipherKey: cipherKey,
                                             encryptionLevel: encryptionLevel,
                                             dbHelper: dbHelper)
        }

        guard let splitDatabase = splitDatabase else {
            Logger.e("Error opening database")
            throw GenericError.couldNotCreateCache
        }

        let flagSetsCache: FlagSetsCache =
        DefaultFlagSetsCache(setsInFilter: splitClientConfig.bySetsFilter()?.values.asSet())
        let persistentSplitsStorage = DefaultPersistentSplitsStorage(database: splitDatabase)
        let generalInfoStorage = openGeneralInfoStorage(database: splitDatabase)
        let splitsStorage = openSplitsStorage(database: splitDatabase, flagSetsCache: flagSetsCache, generalInfoStorage: generalInfoStorage)

        let persistentImpressionsStorage = openPersistentImpressionsStorage(database: splitDatabase)
        let impressionsStorage = openImpressionsStorage(persistentStorage: persistentImpressionsStorage)
        let impressionsCountStorage = openImpressionsCountStorage(database: splitDatabase)

        let persistentEventsStorage = openPersistentEventsStorage(database: splitDatabase)
        let eventsStorage = openEventsStorage(persistentStorage: persistentEventsStorage)

        let mySegmentsStorage = openMySegmentsStorage(database: splitDatabase, generalInfoStorage: generalInfoStorage)
        let myLargeSegmentsStorage = openMyLargeSegmentsStorage(database: splitDatabase, generalInfoStorage: generalInfoStorage)
        let attributesStorage = openAttributesStorage(database: splitDatabase,
                                                      splitClientConfig: splitClientConfig)

        let uniqueKeyStorage: PersistentUniqueKeysStorage =
            DefaultPersistentUniqueKeysStorage(database: splitDatabase,
                                               expirationPeriod: kExpirationPeriod)

        let persistentHashedImpressionsStorage = DefaultPersistentHashedImpressionsStorage(database: splitDatabase)
        let hashedImpressionsStorage = DefaultHashedImpressionsStorage(
            cache: LRUCache(capacity: ServiceConstants.lastSeenImpressionCachSize),
            persistentStorage: persistentHashedImpressionsStorage)

        let persistentRuleBasedSegmentsStorage = DefaultPersistentRuleBasedSegmentsStorage(
            database: splitDatabase,
            generalInfoStorage: generalInfoStorage)

        let ruleBasedSegmentsStorage = DefaultRuleBasedSegmentsStorage(
            persistentStorage: persistentRuleBasedSegmentsStorage, generalInfoStorage: generalInfoStorage)

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
                                     myLargeSegmentsStorage: myLargeSegmentsStorage,
                                     attributesStorage: attributesStorage,
                                     uniqueKeyStorage: uniqueKeyStorage,
                                     flagSetsCache: flagSetsCache,
                                     persistentHashedImpressionsStorage: persistentHashedImpressionsStorage,
                                     hashedImpressionsStorage: hashedImpressionsStorage,
                                     generalInfoStorage: generalInfoStorage,
                                     ruleBasedSegmentsStorage: ruleBasedSegmentsStorage,
                                     persistentRuleBasedSegmentsStorage: persistentRuleBasedSegmentsStorage)
    }

    static func openDatabase(dataFolderName: String,
                             cipherKey: Data?,
                             encryptionLevel: SplitEncryptionLevel,
                             dbHelper: CoreDataHelper) throws -> SplitDatabase {

        return CoreDataSplitDatabase(coreDataHelper: dbHelper,
                                     cipher: createCipher(level: encryptionLevel,
                                                          cipherKey: cipherKey))
    }

    static func openPersistentSplitsStorage(database: SplitDatabase) -> PersistentSplitsStorage {
        return DefaultPersistentSplitsStorage(database: database)
    }

    static func openPersistentRuleBasedSegmentsStorage(database: SplitDatabase, generalInfoStorage: GeneralInfoStorage) -> PersistentRuleBasedSegmentsStorage {
        return DefaultPersistentRuleBasedSegmentsStorage(database: database, generalInfoStorage: generalInfoStorage)
    }

    static func openSplitsStorage(database: SplitDatabase,
                                  flagSetsCache: FlagSetsCache, generalInfoStorage: GeneralInfoStorage) -> SplitsStorage {
        return DefaultSplitsStorage(persistentSplitsStorage: openPersistentSplitsStorage(database: database),
                                    flagSetsCache: flagSetsCache, GeneralInfoStorage: generalInfoStorage)
    }

    static func openPersistentMySegmentsStorage(database: SplitDatabase) -> PersistentMySegmentsStorage {
        return DefaultPersistentMySegmentsStorage(database: database)
    }

    static func openPersistentMyLargeSegmentsStorage(database: SplitDatabase) -> PersistentMySegmentsStorage {
        return DefaultPersistentMyLargeSegmentsStorage(database: database)
    }

    static func openMySegmentsStorage(database: SplitDatabase, generalInfoStorage: GeneralInfoStorage) -> MySegmentsStorage {
        let persistentMySegmentsStorage = openPersistentMySegmentsStorage(database: database)
        return DefaultMySegmentsStorage(persistentMySegmentsStorage: persistentMySegmentsStorage, generalInfoStorage: generalInfoStorage)
    }

    static func openMyLargeSegmentsStorage(database: SplitDatabase, generalInfoStorage: GeneralInfoStorage) -> MySegmentsStorage {
        let persistentMyLargeSegmentsStorage = openPersistentMyLargeSegmentsStorage(database: database)
        return MyLargeSegmentsStorage(persistentStorage: persistentMyLargeSegmentsStorage, generalInfoStorage: generalInfoStorage)
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

    static func openGeneralInfoStorage(database: SplitDatabase) -> GeneralInfoStorage {
        return DefaultGeneralInfoStorage(database: database)
    }

    static func databaseName(prefix: String?, apiKey: String) -> String? {
        if apiKey.count < kDbMagicCharsCount * 2 {
            return nil
        }
        return "\(prefix ?? "")\(apiKey.prefix(kDbMagicCharsCount))\(apiKey.suffix(kDbMagicCharsCount))"
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

    static func createCipher(level: SplitEncryptionLevel, cipherKey: Data?) -> Cipher? {
        if level == .none {
            return nil
        }
        guard let cipherKey = cipherKey else {
            return nil
        }

        return DefaultCipher(cipherKey: cipherKey)
    }

    static func buildDbKey(prefix: String?, sdkKey: String) -> String {
        return "\(prefix ?? "")\(sdkKey)"
    }
}
