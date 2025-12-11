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
        
        // Store canary encrypted with this key
        SplitDatabaseHelper.storeEncryptionCanary(cipherKey: key, generalInfoDao: generalInfoDao)
        
        let exp = expectation(description: "Canary stored")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // Validate with same key
            let isValid = SplitDatabaseHelper.isEncryptionKeyValid(cipherKey: key, generalInfoDao: self.generalInfoDao)
            XCTAssertTrue(isValid)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
    }

    func testNoCanaryPassesValidation() {
        let key = generateTestKey()
        
        // No canary stored - first time setup
        let isValid = SplitDatabaseHelper.isEncryptionKeyValid(cipherKey: key, generalInfoDao: generalInfoDao)
        
        XCTAssertTrue(isValid, "First time setup (no canary) should pass validation")
    }

    func testDifferentKeyFailsCanaryCheck() {
        let originalKey = generateTestKey()
        let differentKey = generateTestKey()
        
        // Store canary with original key
        SplitDatabaseHelper.storeEncryptionCanary(cipherKey: originalKey, generalInfoDao: generalInfoDao)
        
        let exp = expectation(description: "Canary stored")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // Validate with different key
            let isValid = SplitDatabaseHelper.isEncryptionKeyValid(cipherKey: differentKey, generalInfoDao: self.generalInfoDao)
            XCTAssertFalse(isValid, "Different key should fail canary validation")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
    }
    
    func testCorruptedCanaryFailsValidation() {
        let key = generateTestKey()
        
        // Store garbage that can't be decrypted
        generalInfoDao.update(info: .encryptionCanary, stringValue: "not_valid_encrypted_base64_data!!!")
        
        let exp = expectation(description: "Canary stored")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let isValid = SplitDatabaseHelper.isEncryptionKeyValid(cipherKey: key, generalInfoDao: self.generalInfoDao)
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
            let isValid = SplitDatabaseHelper.isEncryptionKeyValid(cipherKey: key, generalInfoDao: self.generalInfoDao)
            XCTAssertFalse(isValid, "Tampered canary (wrong decrypted value) should fail validation")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
    }
    
    // MARK: - Canary Operations Tests
    
    func testStoreEncryptionCanaryCreatesValidCanary() {
        let key = generateTestKey()
        
        SplitDatabaseHelper.storeEncryptionCanary(cipherKey: key, generalInfoDao: generalInfoDao)
        
        let exp = expectation(description: "Canary stored")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // Verify canary was stored
            let stored = self.generalInfoDao.stringValue(info: .encryptionCanary)
            XCTAssertNotNil(stored)
            
            // Verify it's encrypted (not plain text)
            XCTAssertNotEqual("SPLIT_ENC_CHECK", stored)
            
            // Verify it can be validated
            XCTAssertTrue(SplitDatabaseHelper.isEncryptionKeyValid(cipherKey: key, generalInfoDao: self.generalInfoDao))
            exp.fulfill()
        }
        wait(for: [exp], timeout: 3)
    }
    
    /// Test deleteEncryptionCanary removes the canary
    func testDeleteEncryptionCanaryRemovesCanary() {
        let key = generateTestKey()
        SplitDatabaseHelper.storeEncryptionCanary(cipherKey: key, generalInfoDao: generalInfoDao)
        
        let storeExp = expectation(description: "Canary stored")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            storeExp.fulfill()
        }
        wait(for: [storeExp], timeout: 3)
        
        SplitDatabaseHelper.deleteEncryptionCanary(generalInfoDao: generalInfoDao)
        
        let deleteExp = expectation(description: "Canary deleted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let stored = self.generalInfoDao.stringValue(info: .encryptionCanary)
            XCTAssertNil(stored)
            deleteExp.fulfill()
        }
        wait(for: [deleteExp], timeout: 3)
    }
    
    // MARK: - Key Replacement Tests
    
    /// Test replaceEncryptionKey removes key from Keychain and generates new one
    func testReplaceEncryptionKeyGeneratesNewKey() {
        let dbKey = "test_db_key_\(UUID().uuidString.prefix(8))"
        let originalKey = generateTestKey()
        
        // Store original key
        secureStorage.set(item: originalKey.base64EncodedString(), for: .dbEncryptionKey(dbKey))
        
        // Replace key
        let newKey = SplitDatabaseHelper.replaceEncryptionKey(for: dbKey)
        
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
        
        // Clear using CoreDataHelper directly (DbCipher pattern)
        SplitDatabaseHelper.clearAllEncryptedEntities(dbHelper: dbHelper)
        
        let clearExp = expectation(description: "Splits cleared")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(0, db.splitDao.getAll().count)
            clearExp.fulfill()
        }
        wait(for: [clearExp], timeout: 3)
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
        
        SplitDatabaseHelper.clearAllEncryptedEntities(dbHelper: dbHelper)
        
        let clearExp = expectation(description: "Segments cleared")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(db.mySegmentsDao.getBy(userKey: "test_user"))
            clearExp.fulfill()
        }
        wait(for: [clearExp], timeout: 3)
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
        
        SplitDatabaseHelper.clearAllEncryptedEntities(dbHelper: dbHelper)
        
        let clearExp = expectation(description: "Events cleared")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(0, db.eventDao.getBy(createdAt: 0, status: StorageRecordStatus.active, maxRows: 100).count)
            clearExp.fulfill()
        }
        wait(for: [clearExp], timeout: 3)
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
        
        SplitDatabaseHelper.clearAllEncryptedEntities(dbHelper: dbHelper)
        
        let clearExp = expectation(description: "Impressions cleared")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(0, db.impressionDao.getBy(createdAt: 0, status: StorageRecordStatus.active, maxRows: 100).count)
            clearExp.fulfill()
        }
        wait(for: [clearExp], timeout: 3)
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
        
        SplitDatabaseHelper.clearAllEncryptedEntities(dbHelper: dbHelper)
        
        let clearExp = expectation(description: "Attributes cleared")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(db.attributesDao.getBy(userKey: "test_user"))
            clearExp.fulfill()
        }
        wait(for: [clearExp], timeout: 3)
    }
    
    /// Test clearAllEncryptedEntities preserves GeneralInfo (not encrypted)
    func testClearEncryptedEntitiesPreservesGeneralInfo() {
        generalInfoDao.update(info: .splitsChangeNumber, longValue: 12345)
        
        let insertExp = expectation(description: "GeneralInfo inserted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            insertExp.fulfill()
        }
        wait(for: [insertExp], timeout: 3)
        
        SplitDatabaseHelper.clearAllEncryptedEntities(dbHelper: dbHelper)
        
        let clearExp = expectation(description: "GeneralInfo preserved")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // GeneralInfo should NOT be cleared (not encrypted)
            XCTAssertEqual(12345, self.generalInfoDao.longValue(info: .splitsChangeNumber))
            clearExp.fulfill()
        }
        wait(for: [clearExp], timeout: 3)
    }
    
    /// Test clearAllEncryptedEntities preserves hashedImpressions (not encrypted)
    func testClearEncryptedEntitiesPreservesHashedImpressions() {
        // Insert hashed impression directly via CoreDataHelper
        dbHelper.performAndWait {
            if let entity = dbHelper.create(entity: .hashedImpression) as? HashedImpressionEntity {
                entity.impressionHash = 12345
                entity.time = Date().unixTimestamp()
                entity.createdAt = Date().unixTimestamp()
            }
        }
        dbHelper.save()
        
        let insertExp = expectation(description: "HashedImpression inserted")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            insertExp.fulfill()
        }
        wait(for: [insertExp], timeout: 3)
        
        SplitDatabaseHelper.clearAllEncryptedEntities(dbHelper: dbHelper)
        
        let clearExp = expectation(description: "HashedImpressions preserved")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // HashedImpressions should NOT be cleared (not encrypted)
            self.dbHelper.performAndWait {
                let entities = self.dbHelper.fetch(entity: .hashedImpression)
                XCTAssertTrue(entities.count > 0, "HashedImpressions should be preserved")
            }
            clearExp.fulfill()
        }
        wait(for: [clearExp], timeout: 3)
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
            let isValid = SplitDatabaseHelper.isEncryptionKeyValid(
                cipherKey: key,
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
        let cipher = DefaultCipher(cipherKey: originalKey)
        
        // Simulate legacy installation: data encrypted with original key
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
            // No canary exists, data encrypted with original key, validating with wrong key
            let isValid = SplitDatabaseHelper.isEncryptionKeyValid(
                cipherKey: wrongKey,
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
        
        // No data, no canary - but previousEncryptionLevel says encryption was enabled
        // This could happen if encryption was enabled but no data was ever cached
        let isValid = SplitDatabaseHelper.isEncryptionKeyValid(
            cipherKey: key,
            generalInfoDao: generalInfoDao,
            dbHelper: dbHelper,
            previousEncryptionLevel: .aes128Cbc
        )
        
        XCTAssertTrue(isValid, "Legacy installation with no data should pass validation")
    }
    
    /// Test: First time setup (previousEncryptionLevel is none) should pass without checking data
    func testFirstTimeSetupPassesWithoutDataCheck() {
        let key = generateTestKey()
        
        // First time setup - previousEncryptionLevel is .none
        let isValid = SplitDatabaseHelper.isEncryptionKeyValid(
            cipherKey: key,
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
        let cipher = DefaultCipher(cipherKey: originalKey)
        
        // Simulate legacy installation with encrypted data
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
            // Without dbHelper, validation passes (old behavior - can't check data)
            let isValidWithoutHelper = SplitDatabaseHelper.isEncryptionKeyValid(
                cipherKey: wrongKey,
                generalInfoDao: self.generalInfoDao
            )
            
            // With dbHelper, validation fails (new behavior - checks actual data)
            let isValidWithHelper = SplitDatabaseHelper.isEncryptionKeyValid(
                cipherKey: wrongKey,
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
    
    // MARK: - Helpers
    
    private func generateTestKey() -> Data {
        return DefaultKeyGenerator().generateKey(size: ServiceConstants.aes128KeyLength)!
    }
}

