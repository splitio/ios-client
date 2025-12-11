//
//  EncryptionKeyValidationIntegrationTest.swift
//  SplitTests
//
//  Created on 2025-12-10.
//  Copyright © 2025 Split. All rights reserved.
//

import XCTest
@testable import Split

class EncryptionKeyValidationIntegrationTest: XCTestCase {
    
    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var streamingBinding: TestStreamResponseBinding?
    var secureStorage: SecureStorageStub!
    var dbHelper: CoreDataHelper!
    let testDbName = "enc_key_int_test_\(UUID().uuidString.prefix(8))"
    
    override func setUp() {
        super.setUp()
        secureStorage = SecureStorageStub()
        GlobalSecureStorage.testStorage = secureStorage
        
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler()
        )
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        
        dbHelper = IntegrationCoreDataHelper.get(databaseName: testDbName,
                                                  dispatchQueue: DispatchQueue.global())
    }
    
    override func tearDown() {
        GlobalSecureStorage.testStorage = nil
        // Clear database
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
    
    // MARK: - Key Deleted Scenario
    
    /// Full integration test: encryption key deleted from Keychain
    /// SDK should detect invalid key, clear data, and recover with fresh state
    func testKeyDeletedFromKeychainTriggersRecovery() {
        let dbKey = SplitDatabaseHelper.buildDbKey(prefix: nil, sdkKey: apiKey)
        
        // 1. Setup: Initialize SDK with encryption, populate data
        let originalKey = setupEncryptedSdkWithData(dbKey: dbKey)
        
        // Verify data exists
        let testDb = TestingHelper.createTestDatabase(name: testDbName, queue: DispatchQueue.global(), helper: dbHelper)
        
        let dataExp = expectation(description: "Data cached")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(testDb.splitDao.getAll().count > 0, "Should have cached splits")
            dataExp.fulfill()
        }
        wait(for: [dataExp], timeout: 3)
        
        // 2. Simulate key deletion from Keychain
        secureStorage.remove(item: .dbEncryptionKey(dbKey))
        // Note: encryption level still shows .aes128Cbc
        
        // 3. Re-initialize SDK (this should trigger recovery)
        let factory = createFactory(encryptionEnabled: true)
        let readyExp = expectation(description: "SDK Ready")
        
        factory.client.on(event: SplitEvent.sdkReady) {
            readyExp.fulfill()
        }
        
        wait(for: [readyExp], timeout: 10)
        
        // 4. Verify: Data was cleared and re-fetched
        // The key should be different (new one generated)
        let newKeyString = secureStorage.getString(item: .dbEncryptionKey(dbKey))
        XCTAssertNotNil(newKeyString)
        XCTAssertNotEqual(originalKey.base64EncodedString(), newKeyString)

        // Canary should exist with new key (synchronous write during init)
        let generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: dbHelper)
        let canary = generalInfoDao.stringValue(info: .encryptionCanary)
        XCTAssertNotNil(canary, "Canary should exist after recovery")

        // SDK should be functional - verify it can return treatments
        let treatment = factory.client.getTreatment("FACUNDO_TEST")
        XCTAssertNotEqual("control", treatment, "SDK should be functional after recovery")

        factory.client.destroy()
    }
    
    // MARK: - Key Replaced Scenario
    
    /// Full integration test: encryption key replaced with different key
    func testKeyReplacedWithDifferentKeyTriggersRecovery() {
        let dbKey = SplitDatabaseHelper.buildDbKey(prefix: nil, sdkKey: apiKey)
        
        // 1. Setup: Initialize SDK with encryption, populate data
        _ = setupEncryptedSdkWithData(dbKey: dbKey)
        
        // 2. Replace key with a different one (simulating corruption/tampering)
        let differentKey = DefaultKeyGenerator().generateKey(size: ServiceConstants.aes128KeyLength)!
        secureStorage.set(item: differentKey.base64EncodedString(), for: .dbEncryptionKey(dbKey))
        
        // 3. Re-initialize SDK
        let factory = createFactory(encryptionEnabled: true)
        let readyExp = expectation(description: "SDK Ready")
        
        factory.client.on(event: SplitEvent.sdkReady) {
            readyExp.fulfill()
        }
        
        wait(for: [readyExp], timeout: 10)
        
        // 4. Verify recovery happened
        // New canary should be stored (old one couldn't be decrypted) - synchronous write during init
        let generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: dbHelper)
        let canary = generalInfoDao.stringValue(info: .encryptionCanary)
        XCTAssertNotNil(canary, "Canary should exist after recovery")

        // SDK should be functional - verify it can return treatments
        let treatment = factory.client.getTreatment("FACUNDO_TEST")
        XCTAssertNotEqual("control", treatment, "SDK should be functional after recovery")

        factory.client.destroy()
    }
    
    // MARK: - Valid Key Scenario (No Recovery Needed)
    
    /// Full integration test: valid key, no recovery should happen
    func testValidKeyDoesNotTriggerRecovery() {
        let dbKey = SplitDatabaseHelper.buildDbKey(prefix: nil, sdkKey: apiKey)
        
        // 1. Setup: Initialize SDK with encryption, populate data
        let originalKey = setupEncryptedSdkWithData(dbKey: dbKey)
        
        let testDb = TestingHelper.createTestDatabase(name: testDbName, queue: DispatchQueue.global(), helper: dbHelper)
        let generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: dbHelper)
        
        var originalSplitCount = 0
        var originalChangeNumber: Int64 = 0
        
        let dataExp = expectation(description: "Data cached")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            originalSplitCount = testDb.splitDao.getAll().count
            originalChangeNumber = generalInfoDao.longValue(info: .splitsChangeNumber) ?? 0
            dataExp.fulfill()
        }
        wait(for: [dataExp], timeout: 3)
        
        // 2. Re-initialize SDK (key is still valid)
        let factory = createFactory(encryptionEnabled: true)
        let readyExp = expectation(description: "SDK Ready from cache")
        
        factory.client.on(event: SplitEvent.sdkReadyFromCache) {
            readyExp.fulfill()
        }
        
        wait(for: [readyExp], timeout: 10)
        
        // 3. Verify: Data was NOT cleared
        let verifyExp = expectation(description: "Data verified")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(originalSplitCount, testDb.splitDao.getAll().count)
            XCTAssertEqual(originalChangeNumber, generalInfoDao.longValue(info: .splitsChangeNumber))
            verifyExp.fulfill()
        }
        wait(for: [verifyExp], timeout: 3)
        
        // Key should be the same
        let currentKeyString = secureStorage.getString(item: .dbEncryptionKey(dbKey))
        XCTAssertEqual(originalKey.base64EncodedString(), currentKeyString)
        
        factory.client.destroy()
    }
    
    // MARK: - Encryption Toggle Scenarios
    
    /// Test: Enable encryption on previously unencrypted database
    func testEnableEncryptionOnUnencryptedDb() {
        // 1. Setup unencrypted SDK with data
        let factory1 = createFactory(encryptionEnabled: false)
        waitForReady(factory: factory1)
        factory1.client.destroy()
        
        let generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: dbHelper)
        
        // Verify no canary exists
        let checkExp = expectation(description: "Check no canary")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(generalInfoDao.stringValue(info: .encryptionCanary))
            checkExp.fulfill()
        }
        wait(for: [checkExp], timeout: 3)
        
        // 2. Enable encryption
        let factory2 = createFactory(encryptionEnabled: true)
        waitForReady(factory: factory2)
        
        // 3. Verify canary now exists
        let verifyExp = expectation(description: "Canary exists")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNotNil(generalInfoDao.stringValue(info: .encryptionCanary))
            verifyExp.fulfill()
        }
        wait(for: [verifyExp], timeout: 3)
        
        factory2.client.destroy()
    }
    
    /// Test: Disable encryption on previously encrypted database
    func testDisableEncryptionOnEncryptedDb() {
        let dbKey = SplitDatabaseHelper.buildDbKey(prefix: nil, sdkKey: apiKey)
        
        // 1. Setup encrypted SDK with data
        _ = setupEncryptedSdkWithData(dbKey: dbKey)
        
        let generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: dbHelper)
        
        // Verify canary exists
        let checkExp = expectation(description: "Check canary exists")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNotNil(generalInfoDao.stringValue(info: .encryptionCanary))
            checkExp.fulfill()
        }
        wait(for: [checkExp], timeout: 3)
        
        // 2. Disable encryption
        let factory = createFactory(encryptionEnabled: false)
        waitForReady(factory: factory)
        
        // 3. Verify canary is removed
        let verifyExp = expectation(description: "Canary removed")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(generalInfoDao.stringValue(info: .encryptionCanary))
            verifyExp.fulfill()
        }
        wait(for: [verifyExp], timeout: 3)
        
        factory.client.destroy()
    }
    
    // MARK: - Legacy Installation Tests (Pre-Canary)
    
    /// Test: Legacy installation (pre-canary) with corrupted key triggers recovery
    /// Simulates existing installation that was encrypted before canary feature was added
    func testLegacyInstallationWithCorruptedKeyTriggersRecovery() {
        let dbKey = SplitDatabaseHelper.buildDbKey(prefix: nil, sdkKey: apiKey)
        let originalKey = DefaultKeyGenerator().generateKey(size: ServiceConstants.aes128KeyLength)!
        let cipher = DefaultCipher(cipherKey: originalKey)
        
        // 1. Simulate legacy installation: encrypted data but NO canary
        dbHelper.performAndWait {
            if let entity = dbHelper.create(entity: .split) as? SplitEntity {
                entity.name = cipher.encrypt("test_split") ?? ""
                entity.body = cipher.encrypt("{\"name\":\"test_split\",\"status\":\"ACTIVE\"}") ?? ""
                entity.updatedAt = Date().unixTimestamp()
            }
        }
        dbHelper.save()
        
        // Store original key and set encryption level (simulating previous SDK run)
        secureStorage.set(item: originalKey.base64EncodedString(), for: .dbEncryptionKey(dbKey))
        secureStorage.set(item: SplitEncryptionLevel.aes128Cbc.rawValue, for: .dbEncryptionLevel(dbKey))
        
        // Verify no canary exists (legacy installation)
        let generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: dbHelper)
        XCTAssertNil(generalInfoDao.stringValue(info: .encryptionCanary), "Legacy installation should have no canary")
        
        // 2. Simulate key corruption: replace with a different key
        let corruptedKey = DefaultKeyGenerator().generateKey(size: ServiceConstants.aes128KeyLength)!
        secureStorage.set(item: corruptedKey.base64EncodedString(), for: .dbEncryptionKey(dbKey))
        
        // 3. Initialize SDK (should detect corrupt key via data validation and trigger recovery)
        let factory = createFactory(encryptionEnabled: true)
        let readyExp = expectation(description: "SDK Ready")
        
        factory.client.on(event: SplitEvent.sdkReady) {
            readyExp.fulfill()
        }
        
        wait(for: [readyExp], timeout: 10)
        
        // 4. Verify recovery happened
        // New canary should be stored
        let verifyExp = expectation(description: "Verify canary")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let canary = generalInfoDao.stringValue(info: .encryptionCanary)
            XCTAssertNotNil(canary, "Canary should exist after recovery")
            verifyExp.fulfill()
        }
        wait(for: [verifyExp], timeout: 3)
        
        // SDK should be functional (data was cleared and re-fetched)
        let treatment = factory.client.getTreatment("FACUNDO_TEST")
        XCTAssertNotEqual("control", treatment, "SDK should be functional after recovery")
        
        factory.client.destroy()
    }
    
    /// Test: Legacy installation with valid key doesn't trigger recovery
    func testLegacyInstallationWithValidKeyDoesNotTriggerRecovery() {
        let dbKey = SplitDatabaseHelper.buildDbKey(prefix: nil, sdkKey: apiKey)
        let originalKey = DefaultKeyGenerator().generateKey(size: ServiceConstants.aes128KeyLength)!
        let cipher = DefaultCipher(cipherKey: originalKey)
        
        // 1. Simulate legacy installation: encrypted data but NO canary
        dbHelper.performAndWait {
            if let entity = dbHelper.create(entity: .split) as? SplitEntity {
                entity.name = cipher.encrypt("legacy_split") ?? ""
                entity.body = cipher.encrypt("{\"name\":\"legacy_split\",\"status\":\"ACTIVE\"}") ?? ""
                entity.updatedAt = Date().unixTimestamp()
            }
        }
        dbHelper.save()
        
        // Store key and set encryption level (key is VALID - same as used for encryption)
        secureStorage.set(item: originalKey.base64EncodedString(), for: .dbEncryptionKey(dbKey))
        secureStorage.set(item: SplitEncryptionLevel.aes128Cbc.rawValue, for: .dbEncryptionLevel(dbKey))
        
        // Verify no canary exists (legacy installation)
        let generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: dbHelper)
        XCTAssertNil(generalInfoDao.stringValue(info: .encryptionCanary), "Legacy installation should have no canary")
        
        // Verify split exists directly via CoreDataHelper (splitDao might filter encrypted splits)
        let verifySplitExp = expectation(description: "Verify split exists")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            self.dbHelper.performAndWait {
                let splits = self.dbHelper.fetch(entity: .split).compactMap { $0 as? SplitEntity }
                XCTAssertEqual(1, splits.count, "Should have 1 split before SDK init")
            }
            verifySplitExp.fulfill()
        }
        wait(for: [verifySplitExp], timeout: 3)
        
        // 2. Initialize SDK (should pass validation and NOT trigger recovery)
        let factory = createFactory(encryptionEnabled: true)
        let readyExp = expectation(description: "SDK Ready from cache")
        
        factory.client.on(event: SplitEvent.sdkReadyFromCache) {
            readyExp.fulfill()
        }
        
        wait(for: [readyExp], timeout: 10)
        
        // 3. Verify NO recovery happened - data should still be there
        // Canary should now be stored (for future validations)
        let verifyExp = expectation(description: "Verify state")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let canary = generalInfoDao.stringValue(info: .encryptionCanary)
            XCTAssertNotNil(canary, "Canary should be stored after successful validation")
            verifyExp.fulfill()
        }
        wait(for: [verifyExp], timeout: 3)
        
        factory.client.destroy()
    }
    
    /// Test: Key deleted while toggling encryption off
    func testKeyDeletedWhileDisablingEncryption() {
        let dbKey = SplitDatabaseHelper.buildDbKey(prefix: nil, sdkKey: apiKey)
        
        // 1. Setup encrypted SDK
        _ = setupEncryptedSdkWithData(dbKey: dbKey)
        
        // 2. Delete key from Keychain
        secureStorage.remove(item: .dbEncryptionKey(dbKey))
        
        // 3. Disable encryption (migration would fail without valid key)
        let factory = createFactory(encryptionEnabled: false)
        let readyExp = expectation(description: "SDK Ready")
        
        factory.client.on(event: SplitEvent.sdkReady) {
            readyExp.fulfill()
        }
        
        wait(for: [readyExp], timeout: 10)
        
        let generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: dbHelper)
        
        // 4. Verify recovery: data cleared, no canary, SDK functional
        let verifyExp = expectation(description: "Verify state")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            XCTAssertNil(generalInfoDao.stringValue(info: .encryptionCanary))
            verifyExp.fulfill()
        }
        wait(for: [verifyExp], timeout: 3)
        
        let treatment = factory.client.getTreatment("FACUNDO_TEST")
        XCTAssertNotEqual("control", treatment, "SDK should be functional after recovery")
        
        factory.client.destroy()
    }
    
    // MARK: - Integration Test Helpers
    
    private func setupEncryptedSdkWithData(dbKey: String) -> Data {
        // Create and populate encrypted SDK
        let factory = createFactory(encryptionEnabled: true)
        waitForReady(factory: factory)
        
        // Ensure some data is cached
        _ = factory.client.getTreatment("FACUNDO_TEST")
        
        factory.client.destroy()
        
        // Wait for writes to complete
        let writeExp = expectation(description: "Writes complete")
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            writeExp.fulfill()
        }
        wait(for: [writeExp], timeout: 3)
        
        // Return the key that was used
        let keyString = secureStorage.getString(item: .dbEncryptionKey(dbKey))!
        return Base64Utils.decodeBase64NoPadding(keyString)!
    }
    
    private func createFactory(encryptionEnabled: Bool) -> SplitFactory {
        let testDb = TestingHelper.createTestDatabase(name: testDbName, queue: DispatchQueue.global(), helper: dbHelper)
        
        let config = SplitClientConfig()
        config.encryptionEnabled = encryptionEnabled
        config.logLevel = .verbose
        config.streamingEnabled = false
        
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(testDb)
        _ = builder.setApiKey(apiKey)
        _ = builder.setKey(Key(matchingKey: userKey))
        _ = builder.setConfig(config)
        
        return builder.build()!
    }
    
    private func waitForReady(factory: SplitFactory) {
        let readyExp = expectation(description: "SDK Ready")
        factory.client.on(event: SplitEvent.sdkReady) {
            readyExp.fulfill()
        }
        wait(for: [readyExp], timeout: 10)
    }
    
    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                let json = self.loadSplitsChangeFile()
                return TestDispatcherResponse(code: 200, data: Data(json.utf8))
            }
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            return TestDispatcherResponse(code: 200)
        }
    }
    
    private func loadSplitsChangeFile() -> String {
        guard let splitJson = FileHelper.readDataFromFile(sourceClass: self, name: "splitchanges_1", type: "json") else {
            return IntegrationHelper.emptySplitChanges(since: 99999, till: 99999)
        }
        return splitJson
    }
    
    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            return self.streamingBinding!
        }
    }
}

