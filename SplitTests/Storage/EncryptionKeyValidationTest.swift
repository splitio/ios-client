//
//  EncryptionKeyValidationTest.swift
//  SplitTests
//
//  Created on 2025-12-10.
//  Copyright © 2025 Split. All rights reserved.
//

import XCTest
@testable import Split

class EncryptionKeyValidationTest: XCTestCase {
    
    var dbHelper: CoreDataHelper!
    var generalInfoDao: GeneralInfoDao!
    var secureStorage: SecureStorageStub!
    let testDbName = "enc_validation_test_\(UUID().uuidString.prefix(8))"
    
    override func setUp() {
        super.setUp()
        secureStorage = SecureStorageStub()
        GlobalSecureStorage.testStorage = secureStorage
        dbHelper = IntegrationCoreDataHelper.get(databaseName: testDbName,
                                                  dispatchQueue: DispatchQueue.global())
        generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: dbHelper)
    }
    
    override func tearDown() {
        GlobalSecureStorage.testStorage = nil
        // Clear database for next test
        dbHelper.performAndWait {
            dbHelper.deleteAll(entity: .split)
            dbHelper.deleteAll(entity: .mySegment)
            dbHelper.deleteAll(entity: .myLargeSegment)
            dbHelper.deleteAll(entity: .event)
            dbHelper.deleteAll(entity: .impression)
            dbHelper.deleteAll(entity: .impressionsCount)
            dbHelper.deleteAll(entity: .uniqueKey)
            dbHelper.deleteAll(entity: .attribute)
            dbHelper.deleteAll(entity: .ruleBasedSegment)
            dbHelper.deleteAll(entity: .hashedImpression)
            dbHelper.deleteAll(entity: .generalInfo)
        }
        dbHelper.save()
        super.tearDown()
    }
    
    // MARK: - Canary Storage Tests

    func testGeneralInfoEnumHasEncryptionCanaryCase() {
        let info = GeneralInfo.encryptionCanary
        XCTAssertEqual("encryptionCanary", info.rawValue)
    }
    
    func testCanStoreCanaryInGeneralInfo() {
        let canaryValue = "encrypted_test_canary"
        
        generalInfoDao.update(info: .encryptionCanary, stringValue: canaryValue)
        
        // Use expectation for async operation
        let exp = expectation(description: "Canary stored")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let retrieved = self.generalInfoDao.stringValue(info: .encryptionCanary)
            XCTAssertEqual(canaryValue, retrieved)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
    }
    
    func testRetrieveCanaryWhenNoneExistsReturnsNil() {
        let retrieved = generalInfoDao.stringValue(info: .encryptionCanary)
        XCTAssertNil(retrieved)
    }

    func testCanDeleteCanaryFromGeneralInfo() {
        generalInfoDao.update(info: .encryptionCanary, stringValue: "test")
        
        let storeExp = expectation(description: "Canary stored")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            storeExp.fulfill()
        }
        wait(for: [storeExp], timeout: 3)
        
        generalInfoDao.delete(info: .encryptionCanary)
        
        let deleteExp = expectation(description: "Canary deleted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let retrieved = self.generalInfoDao.stringValue(info: .encryptionCanary)
            XCTAssertNil(retrieved)
            deleteExp.fulfill()
        }
        wait(for: [deleteExp], timeout: 3)
    }
    
    // MARK: - Key Validation Logic Tests
    func testValidKeyPassesCanaryCheck() {
        let key = generateTestKey()
        let cipher = DefaultCipher(cipherKey: key)
        
        // Store canary encrypted with this key
        DbEncryptionManager.storeEncryptionCanary(cipher: cipher, dbHelper: dbHelper)
        
        let exp = expectation(description: "Canary stored")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // Validate with same cipher
            let isValid = DbEncryptionManager.isEncryptionKeyValid(cipher: cipher, generalInfoDao: self.generalInfoDao)
            XCTAssertTrue(isValid)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
    }

    func testNoCanaryPassesValidation() {
        let key = generateTestKey()
        let cipher = DefaultCipher(cipherKey: key)
        
        // No canary stored - first time setup
        let isValid = DbEncryptionManager.isEncryptionKeyValid(cipher: cipher, generalInfoDao: generalInfoDao)
        
        XCTAssertTrue(isValid, "First time setup (no canary) should pass validation")
    }

    func testDifferentKeyFailsCanaryCheck() {
        let originalKey = generateTestKey()
        let differentKey = generateTestKey()
        let originalCipher = DefaultCipher(cipherKey: originalKey)
        let differentCipher = DefaultCipher(cipherKey: differentKey)
        
        // Store canary with original cipher
        DbEncryptionManager.storeEncryptionCanary(cipher: originalCipher, dbHelper: dbHelper)
        
        let exp = expectation(description: "Canary stored")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // Validate with different cipher
            let isValid = DbEncryptionManager.isEncryptionKeyValid(cipher: differentCipher, generalInfoDao: self.generalInfoDao)
            XCTAssertFalse(isValid, "Different key should fail canary validation")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
    }
    
    func testCorruptedCanaryFailsValidation() {
        let key = generateTestKey()
        let cipher = DefaultCipher(cipherKey: key)
        
        // Store garbage that can't be decrypted
        generalInfoDao.update(info: .encryptionCanary, stringValue: "not_valid_encrypted_base64_data!!!")
        
        let exp = expectation(description: "Canary stored")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let isValid = DbEncryptionManager.isEncryptionKeyValid(cipher: cipher, generalInfoDao: self.generalInfoDao)
            XCTAssertFalse(isValid, "Corrupted canary should fail validation")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
    }
    
    func testTamperedCanaryFailsValidation() {
        let key = generateTestKey()
        let cipher = DefaultCipher(cipherKey: key)
        
        // Store canary with wrong content (encrypted but not the expected constant)
        let wrongCanary = cipher.encrypt("WRONG_CONSTANT_VALUE")!
        generalInfoDao.update(info: .encryptionCanary, stringValue: wrongCanary)
        
        let exp = expectation(description: "Canary stored")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let isValid = DbEncryptionManager.isEncryptionKeyValid(cipher: cipher, generalInfoDao: self.generalInfoDao)
            XCTAssertFalse(isValid, "Tampered canary (wrong decrypted value) should fail validation")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
    }
    
    // MARK: - Canary Operations Tests
    
    func testStoreEncryptionCanaryCreatesValidCanary() {
        let key = generateTestKey()
        let cipher = DefaultCipher(cipherKey: key)

        // Store canary (synchronous)
        DbEncryptionManager.storeEncryptionCanary(cipher: cipher, dbHelper: dbHelper)

        // Verify immediately - operation is synchronous
        let stored = generalInfoDao.stringValue(info: .encryptionCanary)
        XCTAssertNotNil(stored)

        // Verify it's encrypted (not plain text)
        XCTAssertNotEqual("SPLIT_ENC_CHECK", stored)

        // Verify it can be validated
        XCTAssertTrue(DbEncryptionManager.isEncryptionKeyValid(cipher: cipher, generalInfoDao: generalInfoDao))
    }

    /// Test deleteEncryptionCanary removes the canary
    func testDeleteEncryptionCanaryRemovesCanary() {
        let key = generateTestKey()
        let cipher = DefaultCipher(cipherKey: key)

        // Store canary (synchronous)
        DbEncryptionManager.storeEncryptionCanary(cipher: cipher, dbHelper: dbHelper)

        // Delete canary (synchronous)
        DbEncryptionManager.deleteEncryptionCanary(dbHelper: dbHelper)

        // Verify immediately - operation is synchronous
        let stored = generalInfoDao.stringValue(info: .encryptionCanary)
        XCTAssertNil(stored)
    }
    
    // MARK: - Key Replacement Tests
    
    /// Test replaceEncryptionKey removes key from Keychain and generates new one
    func testReplaceEncryptionKeyGeneratesNewKey() {
        let dbKey = "test_db_key_\(UUID().uuidString.prefix(8))"
        let originalKey = generateTestKey()
        
        // Store original key
        secureStorage.set(item: originalKey.base64EncodedString(), for: .dbEncryptionKey(dbKey))
        
        // Replace key
        let newKey = DbEncryptionManager.replaceEncryptionKey(for: dbKey)
        
        // New key should be generated
        XCTAssertNotNil(newKey)
        XCTAssertEqual(ServiceConstants.aes128KeyLength, newKey?.count)
        
        // Should be different from original
        XCTAssertNotEqual(originalKey, newKey)
        
        // Should be stored in Keychain
        let storedKeyString = secureStorage.getString(item: .dbEncryptionKey(dbKey))
        XCTAssertNotNil(storedKeyString)
        XCTAssertNotEqual(originalKey.base64EncodedString(), storedKeyString)
    }
    
    // MARK: - Clear Encrypted Entities Tests
    // These use CoreDataHelper directly (DbCipher pattern) because clearing
    // happens during initialization, BEFORE Storage classes exist.
    
    /// Test clearAllEncryptedEntities clears splits
    func testClearEncryptedEntitiesClearsSplits() {
        let db = TestingHelper.createTestDatabase(name: testDbName, queue: DispatchQueue.global(), helper: dbHelper)
        db.splitDao.insertOrUpdate(splits: TestingHelper.createSplits())
        
        let insertExp = expectation(description: "Splits inserted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(db.splitDao.getAll().count > 0, "Should have splits before clear")
            insertExp.fulfill()
        }
        wait(for: [insertExp], timeout: 3)
        
        // Clear using CoreDataHelper directly (synchronous)
        DbEncryptionManager.clearAllEncryptedEntities(dbHelper: dbHelper)

        // Verify immediately - operation is synchronous
        XCTAssertEqual(0, db.splitDao.getAll().count)
    }

    /// Test clearAllEncryptedEntities clears mySegments
    func testClearEncryptedEntitiesClearsMySegments() {
        let db = TestingHelper.createTestDatabase(name: testDbName, queue: DispatchQueue.global(), helper: dbHelper)
        db.mySegmentsDao.update(userKey: "test_user", change: SegmentChange(segments: ["s1", "s2"]))
        
        let insertExp = expectation(description: "Segments inserted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            insertExp.fulfill()
        }
        wait(for: [insertExp], timeout: 3)
        
        DbEncryptionManager.clearAllEncryptedEntities(dbHelper: dbHelper)

        // Verify immediately - operation is synchronous
        XCTAssertNil(db.mySegmentsDao.getBy(userKey: "test_user"))
    }

    /// Test clearAllEncryptedEntities clears events
    func testClearEncryptedEntitiesClearsEvents() {
        let db = TestingHelper.createTestDatabase(name: testDbName, queue: DispatchQueue.global(), helper: dbHelper)
        db.eventDao.insert(TestingHelper.createEvents(count: 5))
        
        let insertExp = expectation(description: "Events inserted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            insertExp.fulfill()
        }
        wait(for: [insertExp], timeout: 3)
        
        DbEncryptionManager.clearAllEncryptedEntities(dbHelper: dbHelper)

        // Verify immediately - operation is synchronous
        XCTAssertEqual(0, db.eventDao.getBy(createdAt: 0, status: StorageRecordStatus.active, maxRows: 100).count)
    }

    /// Test clearAllEncryptedEntities clears impressions
    func testClearEncryptedEntitiesClearsImpressions() {
        let db = TestingHelper.createTestDatabase(name: testDbName, queue: DispatchQueue.global(), helper: dbHelper)
        db.impressionDao.insert(TestingHelper.createKeyImpressions())
        
        let insertExp = expectation(description: "Impressions inserted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            insertExp.fulfill()
        }
        wait(for: [insertExp], timeout: 3)
        
        DbEncryptionManager.clearAllEncryptedEntities(dbHelper: dbHelper)

        // Verify immediately - operation is synchronous
        XCTAssertEqual(0, db.impressionDao.getBy(createdAt: 0, status: StorageRecordStatus.active, maxRows: 100).count)
    }

    /// Test clearAllEncryptedEntities clears attributes
    func testClearEncryptedEntitiesClearsAttributes() {
        let db = TestingHelper.createTestDatabase(name: testDbName, queue: DispatchQueue.global(), helper: dbHelper)
        db.attributesDao.update(userKey: "test_user", attributes: ["key": "value"])
        
        let insertExp = expectation(description: "Attributes inserted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            insertExp.fulfill()
        }
        wait(for: [insertExp], timeout: 3)
        
        DbEncryptionManager.clearAllEncryptedEntities(dbHelper: dbHelper)

        // Verify immediately - operation is synchronous
        XCTAssertNil(db.attributesDao.getBy(userKey: "test_user"))
    }

    /// Test clearAllEncryptedEntities preserves GeneralInfo (not encrypted)
    /// Note: Change numbers ARE intentionally reset, but other GeneralInfo fields are preserved
    func testClearEncryptedEntitiesPreservesGeneralInfo() {
        // Use splitsFilterQueryString which should NOT be reset (unlike change numbers)
        generalInfoDao.update(info: .splitsFilterQueryString, stringValue: "test_filter_query")

        let insertExp = expectation(description: "GeneralInfo inserted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            insertExp.fulfill()
        }
        wait(for: [insertExp], timeout: 3)

        DbEncryptionManager.clearAllEncryptedEntities(dbHelper: dbHelper)

        // Verify immediately - operation is synchronous
        // GeneralInfo should NOT be cleared (not encrypted)
        // Note: Change numbers ARE reset intentionally, but other fields are preserved
        XCTAssertEqual("test_filter_query", generalInfoDao.stringValue(info: .splitsFilterQueryString))
    }

    /// Test clearAllEncryptedEntities preserves hashedImpressions (not encrypted)
    func testClearEncryptedEntitiesPreservesHashedImpressions() {
        // Insert hashed impression directly via CoreDataHelper (synchronous)
        dbHelper.performAndWait {
            if let entity = dbHelper.create(entity: .hashedImpression) as? HashedImpressionEntity {
                entity.impressionHash = 12345
                entity.time = Date().unixTimestamp()
                entity.createdAt = Date().unixTimestamp()
            }
        }
        dbHelper.save()

        DbEncryptionManager.clearAllEncryptedEntities(dbHelper: dbHelper)

        // Verify immediately - operation is synchronous
        // HashedImpressions should NOT be cleared (not encrypted)
        dbHelper.performAndWait {
            let entities = dbHelper.fetch(entity: .hashedImpression)
            XCTAssertTrue(entities.count > 0, "HashedImpressions should be preserved")
        }
    }
    
    // MARK: - Legacy Installation Tests (Pre-Canary)
    // (because they were installed before the canary feature was added)
    
    func testLegacyInstallationWithValidDataPassesValidation() {
        let key = generateTestKey()
        let cipher = DefaultCipher(cipherKey: key)
        
        // Simulate legacy installation: encrypted data exists but no canary
        dbHelper.performAndWait {
            if let entity = dbHelper.create(entity: .split) as? SplitEntity {
                entity.name = cipher.encrypt("test_split") ?? ""
                entity.body = cipher.encrypt("{\"name\":\"test_split\"}") ?? ""
                entity.updatedAt = Date().unixTimestamp()
            }
        }
        dbHelper.save()
        
        let exp = expectation(description: "Data inserted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // No canary exists, but data was encrypted with this key
            // previousEncryptionLevel indicates encryption was enabled before
            let isValid = DbEncryptionManager.isEncryptionKeyValid(
                cipher: cipher,
                generalInfoDao: self.generalInfoDao,
                dbHelper: self.dbHelper,
                previousEncryptionLevel: .aes128Cbc
            )
            XCTAssertTrue(isValid, "Legacy installation with valid encrypted data should pass validation")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
    }
    
    /// Test: Legacy installation with encrypted data, no canary, WRONG key
    /// Should fail validation because decryption fails
    func testLegacyInstallationWithWrongKeyFailsValidation() {
        let originalKey = generateTestKey()
        let wrongKey = generateTestKey()
        let originalCipher = DefaultCipher(cipherKey: originalKey)
        let wrongCipher = DefaultCipher(cipherKey: wrongKey)
        
        // Simulate legacy installation: data encrypted with original key
        dbHelper.performAndWait {
            if let entity = dbHelper.create(entity: .split) as? SplitEntity {
                entity.name = originalCipher.encrypt("test_split") ?? ""
                entity.body = originalCipher.encrypt("{\"name\":\"test_split\"}") ?? ""
                entity.updatedAt = Date().unixTimestamp()
            }
        }
        dbHelper.save()
        
        let exp = expectation(description: "Data inserted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // No canary exists, data encrypted with original key, validating with wrong key
            let isValid = DbEncryptionManager.isEncryptionKeyValid(
                cipher: wrongCipher,
                generalInfoDao: self.generalInfoDao,
                dbHelper: self.dbHelper,
                previousEncryptionLevel: .aes128Cbc
            )
            XCTAssertFalse(isValid, "Legacy installation with wrong key should fail validation")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
    }
    
    /// Test: Legacy installation with no data and no canary (empty database)
    /// Should pass validation (truly first time setup)
    func testLegacyInstallationWithNoDataPassesValidation() {
        let key = generateTestKey()
        let cipher = DefaultCipher(cipherKey: key)
        
        // No data, no canary - but previousEncryptionLevel says encryption was enabled
        // This could happen if encryption was enabled but no data was ever cached
        let isValid = DbEncryptionManager.isEncryptionKeyValid(
            cipher: cipher,
            generalInfoDao: generalInfoDao,
            dbHelper: dbHelper,
            previousEncryptionLevel: .aes128Cbc
        )
        
        XCTAssertTrue(isValid, "Legacy installation with no data should pass validation")
    }
    
    /// Test: First time setup (previousEncryptionLevel is none) should pass without checking data
    func testFirstTimeSetupPassesWithoutDataCheck() {
        let key = generateTestKey()
        let cipher = DefaultCipher(cipherKey: key)
        
        // First time setup - previousEncryptionLevel is .none
        let isValid = DbEncryptionManager.isEncryptionKeyValid(
            cipher: cipher,
            generalInfoDao: generalInfoDao,
            dbHelper: dbHelper,
            previousEncryptionLevel: .none
        )
        
        XCTAssertTrue(isValid, "First time setup should pass validation without data check")
    }
    
    /// Test: Legacy installation validation uses dbHelper when provided
    func testLegacyValidationRequiresDbHelper() {
        let originalKey = generateTestKey()
        let wrongKey = generateTestKey()
        let originalCipher = DefaultCipher(cipherKey: originalKey)
        let wrongCipher = DefaultCipher(cipherKey: wrongKey)
        
        // Simulate legacy installation with encrypted data
        dbHelper.performAndWait {
            if let entity = dbHelper.create(entity: .split) as? SplitEntity {
                entity.name = originalCipher.encrypt("test_split") ?? ""
                entity.body = originalCipher.encrypt("{\"name\":\"test_split\"}") ?? ""
                entity.updatedAt = Date().unixTimestamp()
            }
        }
        dbHelper.save()
        
        let exp = expectation(description: "Data inserted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // Without dbHelper, validation passes (old behavior - can't check data)
            let isValidWithoutHelper = DbEncryptionManager.isEncryptionKeyValid(
                cipher: wrongCipher,
                generalInfoDao: self.generalInfoDao
            )
            
            // With dbHelper, validation fails (new behavior - checks actual data)
            let isValidWithHelper = DbEncryptionManager.isEncryptionKeyValid(
                cipher: wrongCipher,
                generalInfoDao: self.generalInfoDao,
                dbHelper: self.dbHelper,
                previousEncryptionLevel: .aes128Cbc
            )
            
            XCTAssertTrue(isValidWithoutHelper, "Without dbHelper, should use old behavior")
            XCTAssertFalse(isValidWithHelper, "With dbHelper and wrong key, should fail")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
    }

    func testMissingCanaryWhenLevelsMatchStoresCanaryUsingCurrentKey() {
        let dbKey = "test_missing_canary_\(UUID().uuidString.prefix(8))"
        let originalKey = generateTestKey()
        let originalCipher = DefaultCipher(cipherKey: originalKey)

        // Setup: Store key and set encryption level (simulating existing encrypted setup)
        secureStorage.set(item: originalKey.base64EncodedString(), for: .dbEncryptionKey(dbKey))
        secureStorage.set(item: SplitEncryptionLevel.aes128Cbc.rawValue, for: .dbEncryptionLevel(dbKey))

        // Verify no canary exists initially
        XCTAssertNil(generalInfoDao.stringValue(info: .encryptionCanary))

        // Call handleEncryptionMigration with same target level but no cipher parameter
        // This simulates the case where levels match but no canary exists
        do {
            try DbEncryptionManager.handleEncryptionMigration(
                dbKey: dbKey,
                targetLevel: .aes128Cbc,
                cipher: nil, // No cipher passed
                cipherKey: nil, // No cipherKey passed
                dbHelper: dbHelper,
                generalInfoDao: generalInfoDao
            )
        } catch {
            XCTFail("handleEncryptionMigration should not throw: \(error)")
        }

        // Verify canary was stored using the key from currentEncryptionKey(for:)
        let exp = expectation(description: "Canary stored")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let storedCanary = self.generalInfoDao.stringValue(info: .encryptionCanary)
            XCTAssertNotNil(storedCanary, "Canary should be stored when missing and levels match")

            // Verify the canary can be decrypted with the original cipher
            let isValid = DbEncryptionManager.isEncryptionKeyValid(
                cipher: originalCipher,
                generalInfoDao: self.generalInfoDao
            )
            XCTAssertTrue(isValid, "Stored canary should be valid with the original key")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
    }

    /// Test: Key deleted from Keychain triggers recovery when encrypted data exists
    /// When key is lost but encrypted data exists, validation fails and recovery is triggered
    func testKeyDeletedWithEncryptedDataTriggersRecovery() {
        let dbKey = "test_key_deleted_recovery_\(UUID().uuidString.prefix(8))"

        // Create original key and encrypt some data with it
        let originalKey = generateTestKey()
        let cipher = DefaultCipher(cipherKey: originalKey)

        // Store the original key in Keychain (simulating a working encrypted setup)
        secureStorage.set(item: originalKey.base64EncodedString(), for: .dbEncryptionKey(dbKey))
        secureStorage.set(item: SplitEncryptionLevel.aes128Cbc.rawValue, for: .dbEncryptionLevel(dbKey))

        // Insert encrypted data with original key (simulating pre-existing encrypted DB)
        dbHelper.performAndWait {
            if let entity = dbHelper.create(entity: .split) as? SplitEntity {
                entity.name = cipher.encrypt("test_split") ?? ""
                entity.body = cipher.encrypt("{\"name\":\"test_split\",\"status\":\"ACTIVE\"}") ?? ""
                entity.updatedAt = Date().unixTimestamp()
            }
        }
        dbHelper.save()

        // Wait for DB write
        let writeExp = expectation(description: "Data written")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            writeExp.fulfill()
        }
        wait(for: [writeExp], timeout: 3)

        // Simulate key deletion from Keychain (user cleared Keychain, system wiped it, etc.)
        secureStorage.remove(item: .dbEncryptionKey(dbKey))
        // Note: Encryption level is still set to .aes128Cbc, but key is gone

        let generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: dbHelper)

        // Verify no canary exists (legacy installation scenario)
        XCTAssertNil(generalInfoDao.stringValue(info: .encryptionCanary))

        // Call validateAndRecoverEncryptionKey
        // Since key was deleted, currentEncryptionKey(for:) will generate a NEW key
        // That new key won't be able to decrypt the data encrypted with originalKey
        let result = DbEncryptionManager.validateAndRecoverEncryptionKey(
            dbKey: dbKey,
            previousLevel: .aes128Cbc, // Previously encrypted
            targetLevel: .aes128Cbc, // Still encrypted
            currentKey: nil, // No current key passed (will be fetched/generated)
            dbHelper: dbHelper,
            generalInfoDao: generalInfoDao
        )

        // Verify recovery was performed (because new key couldn't decrypt existing data)
        XCTAssertTrue(result.recoveryPerformed, "Recovery should be performed when key can't decrypt existing data")

        // Verify new key was generated (different from original)
        XCTAssertNotNil(result.cipherKey, "New cipher key should be generated during recovery")
        XCTAssertNotEqual(originalKey, result.cipherKey, "New key should be different from deleted original key")

        // Verify canary was stored with the new key
        let verifyExp = expectation(description: "Verify recovery state")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let storedCanary = generalInfoDao.stringValue(info: .encryptionCanary)
            XCTAssertNotNil(storedCanary, "Canary should be stored after recovery")

            // Verify encrypted data was cleared
            self.dbHelper.performAndWait {
                let splits = self.dbHelper.fetch(entity: .split).compactMap { $0 as? SplitEntity }
                XCTAssertEqual(0, splits.count, "Encrypted data should be cleared during recovery")
            }

            // Verify the canary can be decrypted with the new cipher
            if let newCipher = result.cipher {
                let isValid = DbEncryptionManager.isEncryptionKeyValid(
                    cipher: newCipher,
                    generalInfoDao: generalInfoDao
                )
                XCTAssertTrue(isValid, "Stored canary should be valid with the new key")
            }
            verifyExp.fulfill()
        }
        wait(for: [verifyExp], timeout: 3)
    }

    // MARK: - Change Number Reset Tests
    
    /// Test: clearAllEncryptedEntities should reset change numbers to -1
    /// This ensures SDK will fetch fresh data from server after recovery
    func testClearAllEncryptedEntitiesResetsChangeNumbers() {
        // Setup: Store high change numbers (simulating existing cached data)
        generalInfoDao.update(info: .splitsChangeNumber, longValue: 99999)
        generalInfoDao.update(info: .splitsUpdateTimestamp, longValue: 1234567890)
        generalInfoDao.update(info: .ruleBasedSegmentsChangeNumber, longValue: 88888)
        
        let setupExp = expectation(description: "Setup complete")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // Verify setup
            XCTAssertEqual(99999, self.generalInfoDao.longValue(info: .splitsChangeNumber))
            XCTAssertEqual(1234567890, self.generalInfoDao.longValue(info: .splitsUpdateTimestamp))
            XCTAssertEqual(88888, self.generalInfoDao.longValue(info: .ruleBasedSegmentsChangeNumber))
            setupExp.fulfill()
        }
        wait(for: [setupExp], timeout: 3)
        
        // Act: Clear all encrypted entities (synchronous)
        DbEncryptionManager.clearAllEncryptedEntities(dbHelper: dbHelper)

        // Assert: Change numbers should be reset immediately (no wait needed - synchronous operation)
        XCTAssertEqual(-1, generalInfoDao.longValue(info: .splitsChangeNumber),
                      "splitsChangeNumber should be reset to -1 after clearing encrypted data")
        XCTAssertEqual(0, generalInfoDao.longValue(info: .splitsUpdateTimestamp),
                      "splitsUpdateTimestamp should be reset to 0 after clearing encrypted data")
        XCTAssertEqual(-1, generalInfoDao.longValue(info: .ruleBasedSegmentsChangeNumber),
                      "ruleBasedSegmentsChangeNumber should be reset to -1 after clearing encrypted data")
    }
    
    /// Test: validateAndRecoverEncryptionKey should reset change numbers during recovery
    /// This is an end-to-end test for the recovery flow
    func testRecoveryResetsChangeNumbers() {
        let dbKey = "test_recovery_change_numbers_\(UUID().uuidString.prefix(8))"
        
        // Setup: Create encrypted data with high change numbers
        let originalKey = generateTestKey()
        let cipher = DefaultCipher(cipherKey: originalKey)
        
        dbHelper.performAndWait {
            if let entity = dbHelper.create(entity: .split) as? SplitEntity {
                entity.name = cipher.encrypt("test_split") ?? ""
                entity.body = cipher.encrypt("{\"name\":\"test_split\",\"status\":\"ACTIVE\"}") ?? ""
                entity.updatedAt = Date().unixTimestamp()
            }
        }
        dbHelper.save()
        
        // Store high change numbers
        generalInfoDao.update(info: .splitsChangeNumber, longValue: 99999)
        generalInfoDao.update(info: .ruleBasedSegmentsChangeNumber, longValue: 88888)
        
        // Simulate key being replaced with a wrong key (triggers recovery)
        let wrongKey = generateTestKey()
        secureStorage.set(item: wrongKey.base64EncodedString(), for: .dbEncryptionKey(dbKey))
        secureStorage.set(item: SplitEncryptionLevel.aes128Cbc.rawValue, for: .dbEncryptionLevel(dbKey))
        
        let setupExp = expectation(description: "Setup complete")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            setupExp.fulfill()
        }
        wait(for: [setupExp], timeout: 3)
        
        // Act: Validate and recover (should fail validation and trigger recovery) - synchronous
        let result = DbEncryptionManager.validateAndRecoverEncryptionKey(
            dbKey: dbKey,
            previousLevel: .aes128Cbc,
            targetLevel: .aes128Cbc,
            currentKey: wrongKey,
            dbHelper: dbHelper,
            generalInfoDao: generalInfoDao
        )

        // Assert: Recovery should have been performed
        XCTAssertTrue(result.recoveryPerformed, "Recovery should be triggered due to wrong key")

        // Assert: Change numbers should be reset immediately (no wait needed - synchronous operation)
        XCTAssertEqual(-1, generalInfoDao.longValue(info: .splitsChangeNumber),
                      "splitsChangeNumber should be reset to -1 after recovery")
        XCTAssertEqual(-1, generalInfoDao.longValue(info: .ruleBasedSegmentsChangeNumber),
                      "ruleBasedSegmentsChangeNumber should be reset to -1 after recovery")
    }
    
    // MARK: - Orphaned Canary Tests (Level Lost)
    
    /// Test: When encryption level is lost from Keychain but key and canary are still valid,
    /// the system should detect this and NOT corrupt data during migration.
    /// This tests the full flow including handleEncryptionMigration.
    func testLevelLostButKeyAndCanaryValidShouldNotCorruptData() {
        let dbKey = "test_level_lost_key_valid_\(UUID().uuidString.prefix(8))"
        
        // Setup: Create a properly encrypted database with key, level, and canary
        let originalKey = generateTestKey()
        let cipher = DefaultCipher(cipherKey: originalKey)
        
        // Store key and level in Keychain
        secureStorage.set(item: originalKey.base64EncodedString(), for: .dbEncryptionKey(dbKey))
        secureStorage.set(item: SplitEncryptionLevel.aes128Cbc.rawValue, for: .dbEncryptionLevel(dbKey))
        
        // Insert encrypted data
        dbHelper.performAndWait {
            if let entity = dbHelper.create(entity: .split) as? SplitEntity {
                entity.name = cipher.encrypt("test_split") ?? ""
                entity.body = cipher.encrypt("{\"name\":\"test_split\",\"status\":\"ACTIVE\"}") ?? ""
                entity.updatedAt = Date().unixTimestamp()
            }
        }
        dbHelper.save()
        
        // Store canary with the valid key
        DbEncryptionManager.storeEncryptionCanary(cipher: cipher, dbHelper: dbHelper)
        
        // Wait for writes
        let writeExp = expectation(description: "Data written")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            writeExp.fulfill()
        }
        wait(for: [writeExp], timeout: 3)
        
        // Verify canary exists and data is decryptable
        XCTAssertNotNil(generalInfoDao.stringValue(info: .encryptionCanary), "Canary should exist")
        
        // Simulate ONLY the encryption level being deleted (key is still there)
        secureStorage.remove(item: .dbEncryptionLevel(dbKey))
        
        // Verify level is now .none but key still exists
        XCTAssertNil(secureStorage.getInt(item: .dbEncryptionLevel(dbKey)), "Level should be nil (deleted)")
        XCTAssertNotNil(secureStorage.getString(item: .dbEncryptionKey(dbKey)), "Key should still exist")
        
        // Simulate the FULL initialization flow:
        // 1. validateAndRecoverEncryptionKey (with previousLevel = .none since it's lost)
        let result = DbEncryptionManager.validateAndRecoverEncryptionKey(
            dbKey: dbKey,
            previousLevel: .none, // Level was lost. This is what SDK would read from Keychain
            targetLevel: .aes128Cbc, // Encryption enabled
            currentKey: originalKey, // Valid key that matches the canary
            dbHelper: dbHelper,
            generalInfoDao: generalInfoDao
        )
        
        // 2. handleEncryptionMigration (if recovery wasn't performed)
        if !result.recoveryPerformed {
            try? DbEncryptionManager.handleEncryptionMigration(
                dbKey: dbKey,
                targetLevel: .aes128Cbc,
                cipher: result.cipher,
                cipherKey: result.cipherKey,
                dbHelper: dbHelper,
                generalInfoDao: generalInfoDao
            )
        }
        
        // Verify data is still decryptable with the ORIGINAL key
        let verifyExp = expectation(description: "Verify data still decryptable")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            self.dbHelper.performAndWait {
                let splits = self.dbHelper.fetch(entity: .split).compactMap { $0 as? SplitEntity }
                XCTAssertEqual(1, splits.count, "Data should be preserved")
                
                if let split = splits.first {
                    // This is the critical assertion:
                    // If handleEncryptionMigration double-encrypted the data,
                    // decrypting with originalKey will produce garbage (not "test_split")
                    let decryptedName = cipher.decrypt(split.name)
                    XCTAssertEqual("test_split", decryptedName, 
                                   "Data should still be decryptable with original key")
                    
                    let decryptedBody = cipher.decrypt(split.body)
                    XCTAssertNotNil(decryptedBody, "Body should be decryptable")
                    if let body = decryptedBody {
                        XCTAssertTrue(body.contains("test_split"), 
                                      "Body should contain expected content")
                    }
                }
            }
            verifyExp.fulfill()
        }
        wait(for: [verifyExp], timeout: 3)
    }
    
    /// Test: When encryption level is lost and key is lost (both deleted),
    /// but canary still exists, recovery should be triggered.
    func testLevelAndKeyBothLostButCanaryExistsShouldTriggerRecovery() {
        let dbKey = "test_level_and_key_lost_\(UUID().uuidString.prefix(8))"
        
        // Setup: Create a properly encrypted database with key, level, and canary
        let originalKey = generateTestKey()
        let cipher = DefaultCipher(cipherKey: originalKey)
        
        // Store key and level in Keychain
        secureStorage.set(item: originalKey.base64EncodedString(), for: .dbEncryptionKey(dbKey))
        secureStorage.set(item: SplitEncryptionLevel.aes128Cbc.rawValue, for: .dbEncryptionLevel(dbKey))
        
        // Insert encrypted data
        dbHelper.performAndWait {
            if let entity = dbHelper.create(entity: .split) as? SplitEntity {
                entity.name = cipher.encrypt("test_split") ?? ""
                entity.body = cipher.encrypt("{\"name\":\"test_split\",\"status\":\"ACTIVE\"}") ?? ""
                entity.updatedAt = Date().unixTimestamp()
            }
        }
        dbHelper.save()
        
        // Store canary with the valid key
        DbEncryptionManager.storeEncryptionCanary(cipher: cipher, dbHelper: dbHelper)
        
        // Wait for writes
        let writeExp = expectation(description: "Data written")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            writeExp.fulfill()
        }
        wait(for: [writeExp], timeout: 3)
        
        // Verify canary exists
        XCTAssertNotNil(generalInfoDao.stringValue(info: .encryptionCanary), "Canary should exist")
        
        // Simulate BOTH level AND key being deleted
        secureStorage.remove(item: .dbEncryptionLevel(dbKey))
        secureStorage.remove(item: .dbEncryptionKey(dbKey))
        
        // Call validateAndRecoverEncryptionKey
        // A new key will be generated since the old one is gone
        let result = DbEncryptionManager.validateAndRecoverEncryptionKey(
            dbKey: dbKey,
            previousLevel: .none, // Level was lost
            targetLevel: .aes128Cbc, // Want encryption enabled
            currentKey: nil, // Key will be generated fresh
            dbHelper: dbHelper,
            generalInfoDao: generalInfoDao
        )
        
        // EXPECTED BEHAVIOR: Canary exists but can't be validated with new key -> recovery
        XCTAssertTrue(result.recoveryPerformed, 
                      "Recovery SHOULD be triggered when both level and key are lost but canary exists")
        
        // Verify data was cleared
        let verifyExp = expectation(description: "Verify data cleared")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            self.dbHelper.performAndWait {
                let splits = self.dbHelper.fetch(entity: .split).compactMap { $0 as? SplitEntity }
                XCTAssertEqual(0, splits.count, "Data should be cleared during recovery")
            }
            verifyExp.fulfill()
        }
        wait(for: [verifyExp], timeout: 3)
    }

    // MARK: - Helpers
    
    private func generateTestKey() -> Data {
        return DefaultKeyGenerator().generateKey(size: ServiceConstants.aes128KeyLength)!
    }
}

