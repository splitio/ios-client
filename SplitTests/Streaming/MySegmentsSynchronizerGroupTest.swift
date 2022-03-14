//
//  mySegmentsSyncGrouphronizerGroupTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 13-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class MySegmentsSynchronizerGroupTest: XCTestCase {

    var mySegmentsSyncGroup: MySegmentsSynchronizerGroup!
    var mySegmentsSyncDic: [String: MySegmentsSynchronizerStub]!

    override func setUp() {
        mySegmentsSyncGroup = DefaultMySegmentsSynchronizerGroup()
        mySegmentsSyncDic = [String: MySegmentsSynchronizerStub]()
        for i in 0..<10 {
            let key = buildKey(i)
            let sync = MySegmentsSynchronizerStub()
            mySegmentsSyncDic[key] = sync
            mySegmentsSyncGroup.append(sync, forKey: key)
        }

    }

    func testAppendRemove() {

        // Add the synchronizer, start periodic fetching. Values should be true
        // Then remove synchronizer, reset stub and test again.
        // Values should be false because synchronizer is not in group anymore
        let key = "someKey"
        let mySegmentSyncStub = MySegmentsSynchronizerStub()
        mySegmentsSyncGroup.append(mySegmentSyncStub, forKey: key)
        mySegmentsSyncGroup.startPeriodicSync()
        mySegmentsSyncGroup.stopPeriodicSync()

        let started = mySegmentSyncStub.startPeriodicFetchingCalled
        let stopped = mySegmentSyncStub.stopPeriodicFetchingCalled

        mySegmentsSyncGroup.remove(forKey: key)
        mySegmentSyncStub.startPeriodicFetchingCalled = false
        mySegmentSyncStub.stopPeriodicFetchingCalled = false

        mySegmentsSyncGroup.startPeriodicSync()
        mySegmentsSyncGroup.stopPeriodicSync()

        XCTAssertTrue(started)
        XCTAssertTrue(stopped)
        XCTAssertFalse(mySegmentSyncStub.startPeriodicFetchingCalled)
        XCTAssertFalse(mySegmentSyncStub.stopPeriodicFetchingCalled)
    }

    func testLoadMySegmentsFromCache() {

        setupTest { key in
            mySegmentsSyncGroup.loadFromCache(forKey: key)
        }

        assertThis { keyNum, sync in
            if keyNum < 5 {
                XCTAssertTrue(sync.loadMySegmentsFromCacheCalled)
            } else {
                XCTAssertFalse(sync.loadMySegmentsFromCacheCalled)
            }
        }
    }

    func testSynchronize() {

        setupTest { key in
            mySegmentsSyncGroup.sync(forKey: key)
        }

        assertThis { keyNum, sync in
            if keyNum < 5 {
                XCTAssertTrue(sync.synchronizeMySegmentsCalled)
            } else {
                XCTAssertFalse(sync.synchronizeMySegmentsCalled)
            }
        }
    }

    func testForceSync() {
        setupTest { key in
            mySegmentsSyncGroup.forceSync(forKey: key)
        }

        assertThis { keyNum, sync in
            if keyNum < 5 {
                XCTAssertTrue(sync.forceMySegmentsSyncCalled)
            } else {
                XCTAssertFalse(sync.forceMySegmentsSyncCalled)
            }
        }
    }

    func testNoPeriodicSync() {
        assertThis { keyNum, sync in
            XCTAssertFalse(sync.startPeriodicFetchingCalled)
            XCTAssertFalse(sync.stopPeriodicFetchingCalled)
        }
    }

    func testPeriodicStartStop() {
        
        mySegmentsSyncGroup.startPeriodicSync()
        mySegmentsSyncGroup.stopPeriodicSync()

        assertThis { keyNum, sync in
            XCTAssertTrue(sync.startPeriodicFetchingCalled)
            XCTAssertTrue(sync.stopPeriodicFetchingCalled)

        }
    }

    func testPeriodicStartPauseResumeStop() {

        mySegmentsSyncGroup.startPeriodicSync()
        mySegmentsSyncGroup.pause()
        mySegmentsSyncGroup.resume()
        mySegmentsSyncGroup.stopPeriodicSync()

        assertThis { keyNum, sync in
            XCTAssertTrue(sync.startPeriodicFetchingCalled)
            XCTAssertTrue(sync.pauseCalled)
            XCTAssertTrue(sync.resumeCalled)
            XCTAssertTrue(sync.stopPeriodicFetchingCalled)
        }
    }

    func testDestroy() {

        mySegmentsSyncGroup.startPeriodicSync()
        mySegmentsSyncGroup.stop()

        assertThis { keyNum, sync in
            XCTAssertTrue(sync.startPeriodicFetchingCalled)
            XCTAssertTrue(sync.stopPeriodicFetchingCalled)
            XCTAssertTrue(sync.destroyCalled)
        }
    }

    private func setupTest(_ test: (String) -> Void) {
        for i in 0..<5 {
            test(buildKey(i))
        }
    }

    private func buildKey(_ num: Int) -> String {
        return "key_\(num)"
    }

    private func assertThis(_ test: (Int, MySegmentsSynchronizerStub) -> Void) {
        for i in 0..<10 {
            let sync = mySegmentsSyncDic[buildKey(i)]!
            test(i, sync)
        }
    }

    override func tearDown() {
    }
}

