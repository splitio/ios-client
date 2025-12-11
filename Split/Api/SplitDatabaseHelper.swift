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

    static func currentEncryptionLevel(dbKey: String) -> SplitEncryptionLevel {
        let rawValue = GlobalSecureStorage.shared.getInt(item: .dbEncryptionLevel(dbKey))
        ?? SplitEncryptionLevel.none.rawValue
        return SplitEncryptionLevel(rawValue: rawValue) ?? .none
    }

    static func setCurrentEncryptionLevel(_ level: SplitEncryptionLevel, for apiKey: String) {
        GlobalSecureStorage.shared.set(item: level.rawValue, for: .dbEncryptionLevel(apiKey))
    }

    static func currentEncryptionKey(for dbKey: String) -> Data? {

        // If there is a stored key, let's use it
        if let encKey = GlobalSecureStorage.shared.getString(item: .dbEncryptionKey(dbKey)) {
            return Base64Utils.decodeBase64NoPadding(encKey)
        }

        // If not, try to create a new one
        if let newKey = DefaultKeyGenerator().generateKey(size: ServiceConstants.aes128KeyLength) {
            setCurrentEncryptionKey(newKey, for: dbKey)
            return newKey
        }

        // If creation fails (even thought it shouldn't) let's use the api key
        if let newKey = dbKey.dataBytes {
            setCurrentEncryptionKey(newKey, for: dbKey)
            return dbKey.dataBytes
        }

        // If everything fails
        return nil
    }

    static func setCurrentEncryptionKey(_ keyBytes: Data, for apiKey: String) {
        GlobalSecureStorage.shared.set(item: keyBytes.base64EncodedString(options: []), for: .dbEncryptionKey(apiKey))
    }

    // MARK: - Encryption Key Validation

    private static let kEncryptionCanaryValue = "SPLIT_ENC_CHECK"

    /// Validates that the provided key can decrypt the stored canary.
    /// For legacy installations (pre-canary), validates by attempting to decrypt actual data.
    /// - Parameters:
    ///   - cipherKey: The encryption key to validate
    ///   - generalInfoDao: DAO for accessing GeneralInfo (canary storage)
    ///   - dbHelper: Optional CoreDataHelper for legacy validation (decrypting actual data)
    ///   - previousEncryptionLevel: The encryption level from previous run (for legacy detection)
    /// - Returns: `true` if validation passes, `false` if key is invalid
    static func isEncryptionKeyValid(
        cipherKey: Data,
        generalInfoDao: GeneralInfoDao,
        dbHelper: CoreDataHelper? = nil,
        previousEncryptionLevel: SplitEncryptionLevel = .none
    ) -> Bool {
        // If canary exists, use it for validation
        if let storedCanary = generalInfoDao.stringValue(info: .encryptionCanary) {
            let cipher = DefaultCipher(cipherKey: cipherKey)
            guard let decrypted = cipher.decrypt(storedCanary) else {
                Logger.w("Encryption canary decryption failed - key may be invalid")
                return false
            }
            
            let isValid = decrypted == kEncryptionCanaryValue
            if !isValid {
                Logger.w("Encryption canary mismatch - key is invalid")
            }
            return isValid
        }
        
        // No canary exists...
        // If previously encrypted and we have dbHelper, validate by decrypting actual data
        // This handles legacy installations (pre-canary) with potentially corrupted keys
        if previousEncryptionLevel != .none, let dbHelper = dbHelper {
            Logger.d("No canary found for previously encrypted database - validating by decrypting data")
            return validateKeyByDecryptingData(cipherKey: cipherKey, dbHelper: dbHelper)
        }
        
        // First time setup or no dbHelper provided - assume valid
        return true
    }
    
    /// Validates key by attempting to decrypt existing data (for pre-canary/legacy installations)
    /// - Returns: `true` if no encrypted data exists OR data decrypts successfully
    /// - Returns: `false` if encrypted data exists but decryption fails
    static func validateKeyByDecryptingData(
        cipherKey: Data,
        dbHelper: CoreDataHelper
    ) -> Bool {
        let cipher = DefaultCipher(cipherKey: cipherKey)
        var isValid = true
        
        dbHelper.performAndWait {
            // Try to decrypt a split (if any exist)
            let splits = dbHelper.fetch(entity: .split).compactMap { $0 as? SplitEntity }
            if let split = splits.first {
                // If body exists (non-empty), try to decrypt it
                let encryptedBody = split.body
                if !encryptedBody.isEmpty {
                    // Decrypt and verify the result is valid JSON (split bodies are JSON)
                    guard let decrypted = cipher.decrypt(encryptedBody),
                          let data = decrypted.data(using: .utf8),
                          (try? JSONSerialization.jsonObject(with: data)) != nil else {
                        Logger.w("Failed to decrypt existing split data - key is invalid")
                        isValid = false
                        return
                    }
                }
            }
            // If no splits exist, key is considered valid (no data to validate against)
        }
        
        return isValid
    }

    /// Stores a new encryption canary encrypted with the provided key
    static func storeEncryptionCanary(
        cipherKey: Data,
        generalInfoDao: GeneralInfoDao
    ) {
        let cipher = DefaultCipher(cipherKey: cipherKey)
        if let encryptedCanary = cipher.encrypt(kEncryptionCanaryValue) {
            generalInfoDao.update(info: .encryptionCanary, stringValue: encryptedCanary)
            Logger.d("Encryption canary stored successfully")
        } else {
            Logger.e("Failed to encrypt canary value")
        }
    }

    /// Deletes the encryption canary
    static func deleteEncryptionCanary(generalInfoDao: GeneralInfoDao) {
        generalInfoDao.delete(info: .encryptionCanary)
        Logger.d("Encryption canary deleted")
    }

    /// Clears all encrypted entities from CoreData.
    /// Follows DbCipher pattern - direct CoreDataHelper access during initialization.
    /// Called when encryption key is invalid and data cannot be recovered.
    static func clearAllEncryptedEntities(dbHelper: CoreDataHelper) {
        Logger.w("Clearing all encrypted entities due to invalid encryption key")
        
        // Same pattern as DbCipher.apply() - direct CoreDataHelper access
        // because this runs BEFORE Storage classes are created
        dbHelper.performAndWait {
            // Encrypted entities (same list as DbCipher operates on)
            dbHelper.deleteAll(entity: .split)
            dbHelper.deleteAll(entity: .mySegment)
            dbHelper.deleteAll(entity: .myLargeSegment)
            dbHelper.deleteAll(entity: .event)
            dbHelper.deleteAll(entity: .impression)
            dbHelper.deleteAll(entity: .impressionsCount)
            dbHelper.deleteAll(entity: .uniqueKey)
            dbHelper.deleteAll(entity: .attribute)
            dbHelper.deleteAll(entity: .ruleBasedSegment)
            
            // NOT cleared (not encrypted):
            // - hashedImpression: stores hashes, not encrypted content
            // - generalInfo: metadata, not encrypted (canary handled separately)
        }
        dbHelper.save()
        
        Logger.d("All encrypted entities cleared")
    }

    /// Removes invalid key from Keychain and generates a fresh one
    static func replaceEncryptionKey(for dbKey: String) -> Data? {
        Logger.w("Replacing encryption key for dbKey: \(dbKey)")
        GlobalSecureStorage.shared.remove(item: .dbEncryptionKey(dbKey))
        return currentEncryptionKey(for: dbKey)
    }

    /// Result of encryption key validation and recovery process
    private struct EncryptionValidationResult {
        let cipherKey: Data?
        let recoveryPerformed: Bool
    }

    /// Validates encryption key and performs recovery if needed
    private static func validateAndRecoverEncryptionKey(
        dbKey: String,
        previousLevel: SplitEncryptionLevel,
        targetLevel: SplitEncryptionLevel,
        currentKey: Data?,
        dbHelper: CoreDataHelper,
        generalInfoDao: GeneralInfoDao
    ) -> EncryptionValidationResult {
        var cipherKey = currentKey
        guard previousLevel != .none else {
            return EncryptionValidationResult(cipherKey: cipherKey, recoveryPerformed: false)
        }
        let keyToValidate = cipherKey ?? currentEncryptionKey(for: dbKey)
        guard let keyToValidate = keyToValidate,
              !isEncryptionKeyValid(cipherKey: keyToValidate, generalInfoDao: generalInfoDao,
                                    dbHelper: dbHelper, previousEncryptionLevel: previousLevel) else {
            return EncryptionValidationResult(cipherKey: cipherKey, recoveryPerformed: false)
        }
        Logger.w("Encryption key validation failed - initiating recovery")
        deleteEncryptionCanary(generalInfoDao: generalInfoDao)
        clearAllEncryptedEntities(dbHelper: dbHelper)
        cipherKey = replaceEncryptionKey(for: dbKey)
        if targetLevel != .none, let newKey = cipherKey {
            storeEncryptionCanary(cipherKey: newKey, generalInfoDao: generalInfoDao)
            setCurrentEncryptionLevel(targetLevel, for: dbKey)
        } else {
            setCurrentEncryptionLevel(.none, for: dbKey)
        }
        return EncryptionValidationResult(cipherKey: cipherKey, recoveryPerformed: true)
    }

    /// Handles encryption migration when levels change
    private static func handleEncryptionMigration(
        dbKey: String,
        targetLevel: SplitEncryptionLevel,
        cipherKey: Data?,
        dbHelper: CoreDataHelper,
        generalInfoDao: GeneralInfoDao
    ) throws {
        let currentStoredLevel = currentEncryptionLevel(dbKey: dbKey)
        if currentStoredLevel != targetLevel,
           let dbCipherKey = cipherKey ?? currentEncryptionKey(for: dbKey) {
            let dbCipher = try DbCipher(cipherKey: dbCipherKey, from: currentStoredLevel,
                                        to: targetLevel, coreDataHelper: dbHelper)
            dbCipher.apply()
            setCurrentEncryptionLevel(targetLevel, for: dbKey)
            if targetLevel != .none {
                storeEncryptionCanary(cipherKey: dbCipherKey, generalInfoDao: generalInfoDao)
            } else {
                deleteEncryptionCanary(generalInfoDao: generalInfoDao)
            }
        }
        // Edge case: Encryption enabled, levels match, but no canary
        if targetLevel != .none,
           generalInfoDao.stringValue(info: .encryptionCanary) == nil,
           let key = cipherKey {
            storeEncryptionCanary(cipherKey: key, generalInfoDao: generalInfoDao)
        }
    }

    static func buildStorageContainer(splitClientConfig: SplitClientConfig,
                                      apiKey: String,
                                      userKey: String,
                                      databaseName: String,
                                      telemetryStorage: TelemetryStorage?,
                                      testDatabase: SplitDatabase?) throws -> SplitStorageContainer {
        let dbKey = buildDbKey(prefix: splitClientConfig.prefix, sdkKey: apiKey)
        let previousEncryptionLevel = currentEncryptionLevel(dbKey: dbKey)
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
        var cipherKey: Data? = encryptionLevel != .none ? currentEncryptionKey(for: dbKey) : nil
        let generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: dbHelper)

        // Validate encryption key and recover if needed
        let validationResult = validateAndRecoverEncryptionKey(
            dbKey: dbKey, previousLevel: previousEncryptionLevel, targetLevel: encryptionLevel,
            currentKey: cipherKey, dbHelper: dbHelper, generalInfoDao: generalInfoDao)
        cipherKey = validationResult.cipherKey

        // Handle migration if recovery wasn't performed
        if !validationResult.recoveryPerformed {
            try handleEncryptionMigration(dbKey: dbKey, targetLevel: encryptionLevel,
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
