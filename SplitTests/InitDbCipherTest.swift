//
//  DbCipherTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28-Mar-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class InitDbCipherTest: XCTestCase {

    var dbHelper: CoreDataHelper!
    var db: SplitDatabase!
    var secureStorage: KeyValueStorage!

    override func setUp() {

        dbHelper = createDbHelper()
        db = TestingHelper.createTestDatabase(name: "test",
                                              queue: DispatchQueue.global(),
                                              helper: dbHelper)
        secureStorage = SecureStorageStub()
    }

    func testEncryptDb() throws {
        GlobalSecureStorage.testStorage = secureStorage
        secureStorage.set(item: SplitEncryptionLevel.none, for: .dbEncryptionLevel)
        let factory = initSdk(encryptionLevel: .aes128Cbc)

        let newEnc = secureStorage.get(item: .dbEncryptionLevel, type: SplitEncryptionLevel.self)

        XCTAssertEqual(SplitEncryptionLevel.aes128Cbc, newEnc)

        factory.client.destroy()
    }

    func testDecryptDb() throws {
        GlobalSecureStorage.testStorage = secureStorage
        secureStorage.set(item: SplitEncryptionLevel.aes128Cbc, for: .dbEncryptionLevel)
        let factory = initSdk(encryptionLevel: .none)

        let newEnc = secureStorage.get(item: .dbEncryptionLevel, type: SplitEncryptionLevel.self)

        XCTAssertEqual(SplitEncryptionLevel.none, newEnc)

        factory.client.destroy()
    }

    private func initSdk(encryptionLevel: SplitEncryptionLevel) -> SplitFactory {
        let config = SplitClientConfig()
        config.dbEncryptionLevel = encryptionLevel

        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(db)
        _ = builder.setApiKey(IntegrationHelper.dummyApiKey)
        _ = builder.setKey(Key(matchingKey: IntegrationHelper.dummyUserKey))
        _ = builder.setConfig(config)

        return builder.build()!
    }

    private func createDbHelper() -> CoreDataHelper {
        return IntegrationCoreDataHelper.get(databaseName: "test",
                                             dispatchQueue: DispatchQueue.global())
    }

    private func createCipher(fromLevel: SplitEncryptionLevel,
                              toLevel: SplitEncryptionLevel,
                              dbHelper: CoreDataHelper) throws -> DbCipher {
        return try DbCipher(apiKey: IntegrationHelper.dummyApiKey,
                            from: fromLevel,
                            to: toLevel,
                            coreDataHelper: dbHelper)
    }
}

