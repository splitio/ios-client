//
//  ImpressionsStorageTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 25-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class ImpressionsStorageTest: XCTestCase {
    var persistentStorage: PersistentImpressionsStorageStub!

    override func setUp() {
        persistentStorage = PersistentImpressionsStorageStub()
    }

    func testStartDisabledPersistence() {
        let impressionsStorage = MainImpressionsStorage(
            persistentStorage: persistentStorage,
            persistenceEnabled: false)

        TestingHelper.createKeyImpressions(feature: "f1", count: 10).forEach {
            impressionsStorage.push($0)
        }

        let count = persistentStorage.storedImpressions.count

        XCTAssertEqual(0, count)
    }

    func testStartEnabledPersistence() {
        let impressionsStorage = MainImpressionsStorage(
            persistentStorage: persistentStorage,
            persistenceEnabled: true)

        TestingHelper.createKeyImpressions(feature: "f1", count: 10).forEach {
            impressionsStorage.push($0)
        }

        let count = persistentStorage.storedImpressions.count

        XCTAssertEqual(10, count)
    }

    func testEnablePersistence() {
        // When enabling persistence data should be persisted and
        // in memory cache cleared
        let impressionsStorage = MainImpressionsStorage(
            persistentStorage: persistentStorage,
            persistenceEnabled: false)

        TestingHelper.createKeyImpressions(feature: "f1", count: 10).forEach {
            impressionsStorage.push($0)
        }

        let countBeforeEnable = persistentStorage.storedImpressions.count

        impressionsStorage.enablePersistence(true)

        TestingHelper.createKeyImpressions(feature: "f12", count: 10).forEach {
            impressionsStorage.push($0)
        }

        let countAfterEnable = persistentStorage.storedImpressions.count

        XCTAssertEqual(0, countBeforeEnable)
        XCTAssertEqual(20, countAfterEnable)
    }

    func testDisablePersistence() {
        // When disabling persistence data should not be persisted
        let impressionsStorage = MainImpressionsStorage(
            persistentStorage: persistentStorage,
            persistenceEnabled: true)

        TestingHelper.createKeyImpressions(feature: "f1", count: 10).forEach {
            impressionsStorage.push($0)
        }

        let countBeforeDisable = persistentStorage.storedImpressions.count

        impressionsStorage.enablePersistence(false)

        TestingHelper.createKeyImpressions(feature: "f12", count: 10).forEach {
            impressionsStorage.push($0)
        }

        let countAfterDisable = persistentStorage.storedImpressions.count

        XCTAssertEqual(10, countBeforeDisable)
        XCTAssertEqual(10, countAfterDisable)
    }

    func testClear() {
        let impressionsStorage = MainImpressionsStorage(
            persistentStorage: persistentStorage,
            persistenceEnabled: false)

        TestingHelper.createKeyImpressions(feature: "f1", count: 10).forEach {
            impressionsStorage.push($0)
        }

        impressionsStorage.clearInMemory()

        impressionsStorage.enablePersistence(true)

        let countAfterEnable = persistentStorage.storedImpressions.count

        // Should be 0 because in memory cache was cleared
        // so no data was available to persist
        XCTAssertEqual(0, countAfterEnable)
    }
}
