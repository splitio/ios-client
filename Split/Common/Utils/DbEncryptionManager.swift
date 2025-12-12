//
//  DbEncryptionManager.swift
//  Split
//
//  Created on 2025-12-11.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation

struct DbEncryptionManager {
    
    // MARK: - Constants
    
    private static let kEncryptionCanaryValue = "SPLIT_ENC_CHECK"
    
    // MARK: - Encryption Level Management
    
    static func currentEncryptionLevel(dbKey: String) -> SplitEncryptionLevel {
        let rawValue = GlobalSecureStorage.shared.getInt(item: .dbEncryptionLevel(dbKey))
        ?? SplitEncryptionLevel.none.rawValue
        return SplitEncryptionLevel(rawValue: rawValue) ?? .none
    }
    
    static func setCurrentEncryptionLevel(_ level: SplitEncryptionLevel, for apiKey: String) {
        GlobalSecureStorage.shared.set(item: level.rawValue, for: .dbEncryptionLevel(apiKey))
    }
    
    // MARK: - Encryption Key Management
    
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
    
    /// Removes invalid key from Keychain and generates a fresh one
    static func replaceEncryptionKey(for dbKey: String) -> Data? {
        Logger.w("Replacing encryption key for dbKey: \(dbKey)")
        GlobalSecureStorage.shared.remove(item: .dbEncryptionKey(dbKey))
        return currentEncryptionKey(for: dbKey)
    }
    
    // MARK: - Encryption Canary Operations
    // Note: These use CoreDataHelper directly for synchronous writes during initialization.
    // This ensures canary is persisted before SDK ready fires.

    /// Stores a new encryption canary encrypted with the provided key (synchronous)
    static func storeEncryptionCanary(
        cipherKey: Data,
        dbHelper: CoreDataHelper
    ) {
        let cipher = DefaultCipher(cipherKey: cipherKey)
        guard let encryptedCanary = cipher.encrypt(kEncryptionCanaryValue) else {
            Logger.e("Failed to encrypt canary value")
            return
        }

        dbHelper.performAndWait {
            let predicate = NSPredicate(format: "name == %@", GeneralInfo.encryptionCanary.rawValue)
            let entities = dbHelper.fetch(entity: .generalInfo, where: predicate)
                .compactMap { $0 as? GeneralInfoEntity }

            let entity: GeneralInfoEntity
            if let existing = entities.first {
                entity = existing
            } else if let new = dbHelper.create(entity: .generalInfo) as? GeneralInfoEntity {
                entity = new
            } else {
                Logger.e("Failed to create GeneralInfoEntity for canary")
                return
            }

            entity.name = GeneralInfo.encryptionCanary.rawValue
            entity.stringValue = encryptedCanary
            entity.updatedAt = Date().unixTimestamp()
        }
        dbHelper.save()
        Logger.d("Encryption canary stored successfully")
    }

    /// Deletes the encryption canary (synchronous)
    static func deleteEncryptionCanary(dbHelper: CoreDataHelper) {
        dbHelper.performAndWait {
            dbHelper.delete(entity: .generalInfo, by: "name", values: [GeneralInfo.encryptionCanary.rawValue])
        }
        dbHelper.save()
        Logger.d("Encryption canary deleted")
    }
    
    // MARK: - Key Validation
    
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
    
    // MARK: - Recovery & Migration
    
    /// Result of encryption key validation and recovery process
    struct EncryptionValidationResult {
        let cipherKey: Data?
        let recoveryPerformed: Bool
    }
    
    /// Validates encryption key and performs recovery if needed
    static func validateAndRecoverEncryptionKey(
        dbKey: String,
        previousLevel: SplitEncryptionLevel,
        targetLevel: SplitEncryptionLevel,
        currentKey: Data?,
        dbHelper: CoreDataHelper,
        generalInfoDao: GeneralInfoDao
    ) -> EncryptionValidationResult {
        // No previous encryption - nothing to validate
        guard previousLevel != .none else {
            return EncryptionValidationResult(cipherKey: currentKey, recoveryPerformed: false)
        }
        
        let keyToValidate = currentKey ?? currentEncryptionKey(for: dbKey)
        
        // Check if key is missing or invalid
        let needsRecovery: Bool
        if let key = keyToValidate {
            needsRecovery = !isEncryptionKeyValid(
                cipherKey: key,
                generalInfoDao: generalInfoDao,
                dbHelper: dbHelper,
                previousEncryptionLevel: previousLevel
            )
            if needsRecovery {
                Logger.w("Encryption key validation failed - initiating recovery")
            }
        } else {
            Logger.w("Encryption was previously enabled but no key available - initiating recovery")
            needsRecovery = true
        }
        
        guard needsRecovery else {
            return EncryptionValidationResult(cipherKey: currentKey, recoveryPerformed: false)
        }
        
        let newKey = performRecovery(dbKey: dbKey, targetLevel: targetLevel, dbHelper: dbHelper)
        return EncryptionValidationResult(cipherKey: newKey, recoveryPerformed: true)
    }
    
    /// Performs recovery by clearing data and generating a new encryption key
    private static func performRecovery(
        dbKey: String,
        targetLevel: SplitEncryptionLevel,
        dbHelper: CoreDataHelper
    ) -> Data? {
        deleteEncryptionCanary(dbHelper: dbHelper)
        clearAllEncryptedEntities(dbHelper: dbHelper)
        
        let newKey = replaceEncryptionKey(for: dbKey)
        
        if targetLevel != .none, let key = newKey {
            storeEncryptionCanary(cipherKey: key, dbHelper: dbHelper)
            setCurrentEncryptionLevel(targetLevel, for: dbKey)
        } else {
            setCurrentEncryptionLevel(.none, for: dbKey)
        }
        
        return newKey
    }
    
    /// Handles encryption migration when levels change
    static func handleEncryptionMigration(
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
                storeEncryptionCanary(cipherKey: dbCipherKey, dbHelper: dbHelper)
            } else {
                deleteEncryptionCanary(dbHelper: dbHelper)
            }
        }
        // Edge case: Encryption enabled, levels match, but no canary
        if targetLevel != .none,
           generalInfoDao.stringValue(info: .encryptionCanary) == nil,
           let key = cipherKey ?? currentEncryptionKey(for: dbKey) {
            storeEncryptionCanary(cipherKey: key, dbHelper: dbHelper)
        }
    }
    
    /// Clears all encrypted entities from CoreData and resets change numbers (synchronous).
    /// Follows DbCipher pattern - direct CoreDataHelper access during initialization.
    /// Called when encryption key is invalid and data cannot be recovered.
    /// - Parameter dbHelper: CoreDataHelper for database operations
    static func clearAllEncryptedEntities(dbHelper: CoreDataHelper) {
        Logger.w("Clearing all encrypted entities due to invalid encryption key")

        // Same pattern as DbCipher.apply() - direct CoreDataHelper access
        // because this runs BEFORE Storage classes are created
        dbHelper.performAndWait {
            // Clear encrypted entities (same list as DbCipher operates on)
            dbHelper.deleteAll(entity: .split)
            dbHelper.deleteAll(entity: .mySegment)
            dbHelper.deleteAll(entity: .myLargeSegment)
            dbHelper.deleteAll(entity: .event)
            dbHelper.deleteAll(entity: .impression)
            dbHelper.deleteAll(entity: .impressionsCount)
            dbHelper.deleteAll(entity: .uniqueKey)
            dbHelper.deleteAll(entity: .attribute)
            dbHelper.deleteAll(entity: .ruleBasedSegment)

            // Reset change numbers synchronously to ensure first splitChanges fetch uses -1
            // Without this, SDK might think it's up-to-date and not fetch new data
            updateGeneralInfoLongValue(dbHelper: dbHelper,
                                       info: .splitsChangeNumber, value: -1)
            updateGeneralInfoLongValue(dbHelper: dbHelper,
                                       info: .splitsUpdateTimestamp, value: 0)
            updateGeneralInfoLongValue(dbHelper: dbHelper,
                                       info: .ruleBasedSegmentsChangeNumber, value: -1)
        }
        dbHelper.save()

        Logger.d("All encrypted entities cleared and change numbers reset")
    }

    /// Helper to synchronously update a GeneralInfo long value
    private static func updateGeneralInfoLongValue(
        dbHelper: CoreDataHelper,
        info: GeneralInfo,
        value: Int64
    ) {
        let predicate = NSPredicate(format: "name == %@", info.rawValue)
        let entities = dbHelper.fetch(entity: .generalInfo, where: predicate)
            .compactMap { $0 as? GeneralInfoEntity }

        let entity: GeneralInfoEntity
        if let existing = entities.first {
            entity = existing
        } else if let new = dbHelper.create(entity: .generalInfo) as? GeneralInfoEntity {
            entity = new
        } else {
            Logger.e("Failed to create GeneralInfoEntity for \(info.rawValue)")
            return
        }

        entity.name = info.rawValue
        entity.stringValue = ""
        entity.longValue = value
        entity.updatedAt = Date().unixTimestamp()
    }
}

