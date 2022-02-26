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

    static func buildStorageContainer(splitClientConfig: SplitClientConfig,
                                      userKey: String,
                                      databaseName: String,
                                      telemetryStorage: TelemetryStorage?,
                                      testDatabase: SplitDatabase?) throws -> SplitStorageContainer {

        let fileStorage = FileStorage(dataFolderName: databaseName)
        let splitDatabase = try openDatabase(dataFolderName: databaseName, testDatabase: testDatabase)

        let persistentSplitsStorage = DefaultPersistentSplitsStorage(database: splitDatabase)
        let splitsStorage = openSplitsStorage(database: splitDatabase)
        let mySegmentsStorage = openMySegmentsStorage(database: splitDatabase, userKey: userKey)
        let impressionsStorage = openImpressionsStorage(database: splitDatabase)
        let impressionsCountStorage = openImpressionsCountStorage(database: splitDatabase)
        let eventsStorage = openEventsStorage(database: splitDatabase)
        let attributesStorage = openAttributesStorage(database: splitDatabase,
                                                      userKey: userKey,
                                                      splitClientConfig: splitClientConfig)

        return SplitStorageContainer(splitDatabase: splitDatabase,
                                     fileStorage: fileStorage,
                                     splitsStorage: splitsStorage,
                                     persistentSplitsStorage: persistentSplitsStorage,
                                     mySegmentsStorage: mySegmentsStorage,
                                     impressionsStorage: impressionsStorage,
                                     impressionsCountStorage: impressionsCountStorage,
                                     eventsStorage: eventsStorage,
                                     attributesStorage: attributesStorage,
                                     telemetryStorage: telemetryStorage)
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

    static func openPersistentAttributesStorage(database: SplitDatabase,
                                                userKey: String) -> PersistentAttributesStorage {
        return DefaultPersistentAttributesStorage(userKey: userKey, database: database)
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

    static func openAttributesStorage(database: SplitDatabase,
                                      userKey: String,
                                      splitClientConfig: SplitClientConfig) -> AttributesStorage {
        return DefaultAttributesStorage(
            persistentAttributesStorage: splitClientConfig.persistentAttributesEnabled ?
                openPersistentAttributesStorage(database: database, userKey: userKey) : nil
        )
    }

    static func databaseName(apiKey: String) -> String? {
        if apiKey.count < kDbMagicCharsCount {
            return nil
        }
        return "\(apiKey.prefix(kDbMagicCharsCount))\(apiKey.suffix(kDbMagicCharsCount))"
    }

    static func renameDatabaseFromLegacyName(name dbName: String, apiKey: String) {
        let fileManager = FileManager.default
        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            fatalError("Unable to resolve document directory")
        }

        // Checking if database without hashing exists
        // If so, renaming was already done
        let databaseUrl = docURL.appendingPathComponent("\(dbName).\(ServiceConstants.databaseExtension)")
        if fileManager.fileExists(atPath: databaseUrl.path) {
            return
        }

        guard let legacyName = legacyDbName(from: apiKey) else {
            return
        }

        // Renaming all database files
        do {
            for ext in kDbExt {
                let fullExt = "\(ServiceConstants.databaseExtension)\(ext)"
                let legacyDbFile = docURL.appendingPathComponent("\(legacyName).\(fullExt)")
                let newDbFile = docURL.appendingPathComponent("\(dbName).\(fullExt)")
                try fileManager.moveItem(at: legacyDbFile, to: newDbFile)
            }
        } catch {
            Logger.w("Unable to rename legacy db. Avoiding migration. Message: \(error.localizedDescription)")
        }
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

}
