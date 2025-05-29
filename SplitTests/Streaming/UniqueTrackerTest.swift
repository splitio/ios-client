//
//  UniqueTrackerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 20-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class UniqueKeyTrackerTest: XCTestCase {
    var uniqueKeyStorage: PersistentUniqueKeyStorageStub!
    var tracker: UniqueKeyTracker!

    override func setUp() {
        uniqueKeyStorage = PersistentUniqueKeyStorageStub()
        tracker = DefaultUniqueKeyTracker(persistentUniqueKeyStorage: uniqueKeyStorage)
    }

    func testTrackAndSave() {
        for i in 0 ..< 10 {
            track(userKey: "key1", featureNb: i)
        }

        for i in 5 ..< 10 {
            track(userKey: "key2", featureNb: i)
        }

        tracker.saveAndClear()

        let save1 = uniqueKeyStorage.uniqueKeys
        uniqueKeyStorage.clear()

        tracker.saveAndClear()

        let save2 = uniqueKeyStorage.uniqueKeys

        XCTAssertEqual(2, save1.count)
        XCTAssertEqual(10, save1.values.filter { $0.uniqueKey.userKey == "key1" }[0].uniqueKey.features.count)
        XCTAssertEqual(5, save1.values.filter { $0.uniqueKey.userKey == "key2" }[0].uniqueKey.features.count)
        XCTAssertEqual(0, save2.count)
    }

    private func track(userKey: String, featureNb: Int) {
        tracker.track(userKey: userKey, featureName: "feature\(featureNb)")
    }

    override func tearDown() {}
}
