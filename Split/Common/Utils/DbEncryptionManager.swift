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
        var cipherKey = currentKey
        guard previousLevel != .none else {
            return EncryptionValidationResult(cipherKey: cipherKey, recoveryPerformed: false)
        }
        let keyToValidate = cipherKey ?? currentEncryptionKey(for: dbKey)
        guard let keyToValidate = keyToValidate else {
            // If we previously had encryption enabled but can't get a key to validate,
            // treat this as invalid and trigger recovery
            if previousLevel != .none {
                Logger.w("Encryption was previously enabled but no key available for validation - initiating recovery")
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
            return EncryptionValidationResult(cipherKey: cipherKey, recoveryPerformed: false)
        }
        guard !isEncryptionKeyValid(cipherKey: keyToValidate, generalInfoDao: generalInfoDao,
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
                storeEncryptionCanary(cipherKey: dbCipherKey, generalInfoDao: generalInfoDao)
            } else {
                deleteEncryptionCanary(generalInfoDao: generalInfoDao)
            }
        }
        // Edge case: Encryption enabled, levels match, but no canary
        if targetLevel != .none,
           generalInfoDao.stringValue(info: .encryptionCanary) == nil,
           let key = cipherKey ?? currentEncryptionKey(for: dbKey) {
            storeEncryptionCanary(cipherKey: key, generalInfoDao: generalInfoDao)
        }
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
        }
        dbHelper.save()
        
        Logger.d("All encrypted entities cleared")
    }
}

