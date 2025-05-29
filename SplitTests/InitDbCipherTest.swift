//
//  DbCipherTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28-Mar-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class InitDbCipherTest: XCTestCase {
    var dbHelper: CoreDataHelper!
    var db: SplitDatabase!
    let apiKey1 = IntegrationHelper.dummyApiKey
    let apiKey2 = "42bc399049fd8653247c5ea42bc3c1ae2c6a"
    var secureStorage = SecureStorageStub()
    override func setUp() {
        GlobalSecureStorage.testStorage = secureStorage
        dbHelper = createDbHelper()
        db = TestingHelper.createTestDatabase(
            name: "test",
            queue: DispatchQueue.test,
            helper: dbHelper)
    }

    func testEncryptDb() throws {
        secureStorage.set(item: SplitEncryptionLevel.none.rawValue, for: .dbEncryptionLevel(apiKey1))

        let factory = initSdk(encryptionEnabled: true, apiKey: apiKey1)

        let newEnc = secureStorage.getInt(item: .dbEncryptionLevel(apiKey1))

        XCTAssertEqual(SplitEncryptionLevel.aes128Cbc.rawValue, newEnc)

        factory.client.destroy()
    }

    func testDecryptDb() throws {
        secureStorage.set(item: SplitEncryptionLevel.aes128Cbc.rawValue, for: .dbEncryptionLevel(apiKey2))
        let factory = initSdk(encryptionEnabled: false, apiKey: apiKey2)

        let newEnc = secureStorage.getInt(item: .dbEncryptionLevel(apiKey2))
        XCTAssertEqual(SplitEncryptionLevel.none.rawValue, newEnc)

        factory.client.destroy()
    }

    private func initSdk(encryptionEnabled: Bool, apiKey: String) -> SplitFactory {
        let config = SplitClientConfig()
        config.encryptionEnabled = encryptionEnabled

        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(db)
        _ = builder.setApiKey(apiKey)
        _ = builder.setKey(Key(matchingKey: IntegrationHelper.dummyUserKey))
        _ = builder.setConfig(config)

        return builder.build()!
    }

    private func createDbHelper() -> CoreDataHelper {
        return IntegrationCoreDataHelper.get(
            databaseName: "test",
            dispatchQueue: DispatchQueue.global())
    }

    private func createCipher(
        fromLevel: SplitEncryptionLevel,
        toLevel: SplitEncryptionLevel,
        dbHelper: CoreDataHelper) throws -> DbCipher {
        return try DbCipher(
            cipherKey: IntegrationHelper.dummyCipherKey,
            from: fromLevel,
            to: toLevel,
            coreDataHelper: dbHelper)
    }
}
