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
                                      userKey: String,
                                      databaseName: String,
                                      telemetryStorage: TelemetryStorage?,
                                      testDatabase: SplitDatabase?) throws -> SplitStorageContainer {

        let fileStorage = FileStorage(dataFolderName: databaseName)
        let splitDatabase = try openDatabase(dataFolderName: databaseName, testDatabase: testDatabase)

        let persistentSplitsStorage = DefaultPersistentSplitsStorage(database: splitDatabase)
        let splitsStorage = openSplitsStorage(database: splitDatabase)

        let impressionsStorage = openImpressionsStorage(database: splitDatabase)
        let impressionsCountStorage = openImpressionsCountStorage(database: splitDatabase)
        let eventsStorage = openEventsStorage(database: splitDatabase)

        let mySegmentsStorage = openMySegmentsStorage(database: splitDatabase)
        let attributesStorage = openAttributesStorage(database: splitDatabase,
                                                      splitClientConfig: splitClientConfig)

        var uniqueKeyStorage: PersistentUniqueKeysStorage?
        if splitClientConfig.finalImpressionsMode == .none {
            uniqueKeyStorage =
            DefaultPersistentUniqueKeysStorage(database: splitDatabase,
                                               expirationPeriod: kExpirationPeriod)
        }

        return SplitStorageContainer(splitDatabase: splitDatabase,
                                     fileStorage: fileStorage,
                                     splitsStorage: splitsStorage,
                                     persistentSplitsStorage: persistentSplitsStorage,
                                     impressionsStorage: impressionsStorage,
                                     impressionsCountStorage: impressionsCountStorage,
                                     eventsStorage: eventsStorage,
                                     telemetryStorage: telemetryStorage,
                                     mySegmentsStorage: mySegmentsStorage,
                                     attributesStorage: attributesStorage,
                                     uniqueKeyStorage: uniqueKeyStorage)
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
        let fileManager = FileManager.default
        guard let docUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            Logger.d("Could not find document directory")
            return
        }
        guard let cacheUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last else {
            Logger.d("Could not find cache directory")
            return
        }

        let fullDbName = "\(dbName).\(ServiceConstants.databaseExtension)"
        let cacheDbUrl = cacheUrl.appendingPathComponent("\(fullDbName)")
        // Checking if database in cache folder exists
        // If so, work is done here
        if fileManager.fileExists(atPath: cacheDbUrl.path) {
            return
        }

        // Checking if database without hashing exists
        // in documents
        // If so, moving to cache folder
        if fileManager.fileExists(atPath: docUrl.appendingPathComponent("\(fullDbName)").path) {
            moveDbFiles(fromFolder: docUrl, fromName: dbName,
                        toFolder: cacheUrl, toName: dbName)
            return
        }

        // Checking if database hashed name exists
        // in documents
        // If so, moving to cache folder without a hashed name
        guard let legacyName = legacyDbName(from: apiKey) else {
            return
        }
        moveDbFiles(fromFolder: docUrl, fromName: legacyName,
                    toFolder: cacheUrl, toName: dbName)
    }

    static func moveDbFiles(fromFolder: URL, fromName: String,
                            toFolder: URL, toName: String) {
        do {
            for ext in kDbExt {
                let fullExt = "\(ServiceConstants.databaseExtension)\(ext)"
                let fromDbFile = fromFolder.appendingPathComponent("\(fromName).\(fullExt)")
                let newDbFile = toFolder.appendingPathComponent("\(toName).\(fullExt)")
                try FileManager.default.moveItem(at: fromDbFile, to: newDbFile)
            }
        } catch {
            Logger.d("Unable to rename / move old db file. Avoiding migration. Message: \(error.localizedDescription)")
        }
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

    static func legacyDbName(from apiKey: String) -> String? {
        let kSaltLength = 29
        let kSaltPrefix = "$2a$10$"
        let kCharToFillSalt = "A"
        let sanitizedApiKey = SplitDatabaseHelper.sanitizeForFolderName(apiKey)
        var salt = kSaltPrefix
        if sanitizedApiKey.count >= kSaltLength - kSaltPrefix.count {
            let endIndex = sanitizedApiKey.index(sanitizedApiKey.startIndex,
                                                 offsetBy: kSaltLength - kSaltPrefix.count)
            salt.append(String(sanitizedApiKey[..<endIndex]))
        } else {
            salt.append(sanitizedApiKey)
            salt.append(contentsOf: String(repeating: kCharToFillSalt,
                                           count: (kSaltLength - kSaltPrefix.count) - sanitizedApiKey.count))
        }
        if let hash = HashHelper.hash(sanitizedApiKey, salt: salt) {
            return SplitDatabaseHelper.sanitizeForFolderName(hash)
        }
        return nil
    }

    static func createByKeyMySegmentsStorage(mySegmentsStorage: MySegmentsStorage,
                                             userKey: String) -> ByKeyMySegmentsStorage {
        return DefaultByKeyMySegmentsStorage(mySegmentsStorage: mySegmentsStorage, userKey: userKey)
    }
}
