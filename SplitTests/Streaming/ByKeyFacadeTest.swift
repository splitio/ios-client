//
//  ByKeyFacadeTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 13-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class ByKeyFacadeTest: XCTestCase {
    var byKeyFacade: ByKeyFacade!
    var componentGroups: [Key: ByKeyComponentGroup]!

    override func setUp() {
        byKeyFacade = DefaultByKeyFacade()
        componentGroups = [Key: ByKeyComponentGroup]()
        for i in 0 ..< 10 {
            let key = buildKey(i)
            let attrStorage = ByKeyAttributesStorageStub(
                userKey: key.matchingKey,
                attributesStorage: AttributesStorageStub())
            let group = ByKeyComponentGroup(
                splitClient: SplitClientStub(),
                eventsManager: SplitEventsManagerStub(),
                mySegmentsSynchronizer: MySegmentsSynchronizerStub(),
                attributesStorage: attrStorage)
            componentGroups[key] = group
            byKeyFacade.append(group, forKey: key)
        }
    }

    func testAppendRemove() {
        // Add the group, start periodic fetching. Values should be true
        // Then remove synchronizer, reset stub and test again.
        // Values should be false because synchronizer is not in group anymore
        let key = Key(matchingKey: "someKey")
        let attributesStorage = ByKeyAttributesStorageStub(
            userKey: key.matchingKey,
            attributesStorage: AttributesStorageStub())
        let group = ByKeyComponentGroup(
            splitClient: SplitClientStub(),
            eventsManager: SplitEventsManagerStub(),
            mySegmentsSynchronizer: MySegmentsSynchronizerStub(),
            attributesStorage: attributesStorage)
        byKeyFacade.append(group, forKey: key)
        byKeyFacade.startPeriodicSync()
        byKeyFacade.stopPeriodicSync()

        var res = [String: Bool]()
        for (gkey, gvalue) in componentGroups {
            res[buildMapKey(key: gkey, function: "started")] = stub(gvalue.mySegmentsSynchronizer)
                .startPeriodicFetchingCalled
            res[buildMapKey(key: gkey, function: "stopped")] = stub(gvalue.mySegmentsSynchronizer)
                .stopPeriodicFetchingCalled
        }

        for (_, gvalue) in componentGroups {
            let syncStub = stub(gvalue.mySegmentsSynchronizer)
            syncStub.startPeriodicFetchingCalled = false
            syncStub.stopPeriodicFetchingCalled = false
        }

        _ = byKeyFacade.removeAndCount(forKey: key)

        byKeyFacade.startPeriodicSync()
        byKeyFacade.stopPeriodicSync()

        var res1 = [String: Bool]()
        for (gkey, gvalue) in componentGroups {
            res1[buildMapKey(key: gkey, function: "started")] = stub(gvalue.mySegmentsSynchronizer)
                .startPeriodicFetchingCalled
            res1[buildMapKey(key: gkey, function: "stopped")] = stub(gvalue.mySegmentsSynchronizer)
                .stopPeriodicFetchingCalled
        }

        for (_, value) in res {
            XCTAssertTrue(value)
            XCTAssertTrue(value)
        }
    }

    func testLoadDataFromCache() {
        setupTest { key in
            byKeyFacade.loadMySegmentsFromCache(forKey: key.matchingKey)
            byKeyFacade.loadAttributesFromCache(forKey: key.matchingKey)
        }
        sleep(1)
        assertThis { keyNum, group in
            if keyNum < 5 {
                XCTAssertTrue(stub(group.mySegmentsSynchronizer).loadMySegmentsFromCacheCalled)
                XCTAssertTrue(stub(group.attributesStorage).loadLocalCalled)
            } else {
                XCTAssertFalse(stub(group.mySegmentsSynchronizer).loadMySegmentsFromCacheCalled)
                XCTAssertFalse(stub(group.attributesStorage).loadLocalCalled)
            }
        }
    }

    func testSynchronize() {
        setupTest { key in
            byKeyFacade.syncMySegments(forKey: key.matchingKey)
        }

        assertThis { keyNum, group in
            if keyNum < 5 {
                XCTAssertTrue(stub(group.mySegmentsSynchronizer).synchronizeMySegmentsCalled)
            } else {
                XCTAssertFalse(stub(group.mySegmentsSynchronizer).synchronizeMySegmentsCalled)
            }
        }
    }

    func testForceSync() {
        setupTest { key, i in
            let cn = i * 100
            let cns = SegmentsChangeNumber(msChangeNumber: cn.asInt64(), mlsChangeNumber: cn.asInt64() + 100)
            let delay = i * 10
            byKeyFacade.forceMySegmentsSync(forKey: key.matchingKey, changeNumbers: cns, delay: delay.asInt64())
        }

        assertThis { keyNum, group in
            let sync = stub(group.mySegmentsSynchronizer)
            let params: ForceMySegmentsParams? = sync.forceMySegmentsSyncParams
            if keyNum < 5 {
                XCTAssertEqual(params?.segmentsCn.msChangeNumber, (keyNum * 100).asInt64())
                XCTAssertEqual(params?.segmentsCn.mlsChangeNumber, (keyNum * 100 + 100).asInt64())
                XCTAssertEqual(params?.delay, (keyNum * 10).asInt64())
                XCTAssertTrue(sync.forceMySegmentsSyncCalled)
            } else {
                XCTAssertFalse(sync.forceMySegmentsSyncCalled)
            }
        }
    }

    func testNoPeriodicSync() {
        assertThis { keyNum, group in
            XCTAssertFalse(stub(group.mySegmentsSynchronizer).startPeriodicFetchingCalled)
            XCTAssertFalse(stub(group.mySegmentsSynchronizer).stopPeriodicFetchingCalled)
        }
    }

    func testPeriodicStartStop() {
        byKeyFacade.startPeriodicSync()
        byKeyFacade.stopPeriodicSync()

        assertThis { keyNum, group in
            XCTAssertTrue(stub(group.mySegmentsSynchronizer).startPeriodicFetchingCalled)
            XCTAssertTrue(stub(group.mySegmentsSynchronizer).stopPeriodicFetchingCalled)
        }
    }

    func testPeriodicStartPauseResumeStop() {
        byKeyFacade.startPeriodicSync()
        byKeyFacade.pause()
        byKeyFacade.resume()
        byKeyFacade.stopPeriodicSync()

        assertThis { keyNum, group in
            XCTAssertTrue(stub(group.mySegmentsSynchronizer).startPeriodicFetchingCalled)
            XCTAssertTrue(stub(group.mySegmentsSynchronizer).pauseCalled)
            XCTAssertTrue(stub(group.mySegmentsSynchronizer).resumeCalled)
            XCTAssertTrue(stub(group.mySegmentsSynchronizer).stopPeriodicFetchingCalled)
        }
    }

    func testDestroy() {
        byKeyFacade.startPeriodicSync()
        byKeyFacade.stop()

        assertThis { keyNum, group in
            XCTAssertTrue(stub(group.mySegmentsSynchronizer).startPeriodicFetchingCalled)
            XCTAssertTrue(stub(group.mySegmentsSynchronizer).stopPeriodicFetchingCalled)
            XCTAssertTrue(stub(group.mySegmentsSynchronizer).destroyCalled)
            XCTAssertTrue(stub(group.attributesStorage).destroyCalled)
            XCTAssertTrue(stub(group.eventsManager).stopCalled)
        }
    }

    func testStartSyncForKey() {
        setupTest { key in
            byKeyFacade.startSync(forKey: key)
        }

        assertThis { keyNum, group in
            if keyNum < 5 {
                XCTAssertTrue(stub(group.mySegmentsSynchronizer).loadMySegmentsFromCacheCalled)
                XCTAssertTrue(stub(group.mySegmentsSynchronizer).synchronizeMySegmentsCalled)
                XCTAssertTrue(stub(group.attributesStorage).loadLocalCalled)
                XCTAssertFalse(stub(group.mySegmentsSynchronizer).startPeriodicFetchingCalled)
            }
        }
    }

    func testStartSyncForKeyPolling() {
        byKeyFacade.startPeriodicSync()
        setupTest { key in
            byKeyFacade.startSync(forKey: key)
        }

        assertThis { keyNum, group in
            if keyNum < 5 {
                XCTAssertTrue(stub(group.mySegmentsSynchronizer).loadMySegmentsFromCacheCalled)
                XCTAssertTrue(stub(group.mySegmentsSynchronizer).synchronizeMySegmentsCalled)
                XCTAssertTrue(stub(group.attributesStorage).loadLocalCalled)
                XCTAssertTrue(stub(group.mySegmentsSynchronizer).startPeriodicFetchingCalled)
            }
        }
    }

    private func setupTest(_ test: (Key) -> Void) {
        for i in 0 ..< 5 {
            test(buildKey(i))
        }
    }

    private func setupTest(_ test: (Key, Int) -> Void) {
        for i in 0 ..< 5 {
            test(buildKey(i), i)
        }
    }

    private func buildKey(_ num: Int) -> Key {
        return Key(matchingKey: "key_\(num)")
    }

    private func assertThis(_ test: (Int, ByKeyComponentGroup) -> Void) {
        for i in 0 ..< 10 {
            let sync = componentGroups[buildKey(i)]!
            test(i, sync)
        }
    }

    func stub(_ mySegmentsSynchronizer: MySegmentsSynchronizer) -> MySegmentsSynchronizerStub {
        return mySegmentsSynchronizer as! MySegmentsSynchronizerStub
    }

    func stub(_ eventsManager: SplitEventsManager) -> SplitEventsManagerStub {
        return eventsManager as! SplitEventsManagerStub
    }

    func stub(_ attributesStorage: ByKeyAttributesStorage) -> ByKeyAttributesStorageStub {
        return attributesStorage as! ByKeyAttributesStorageStub
    }

    private func buildMapKey(key: Key, function: String) -> String {
        return "\(key.matchingKey)_\(function)"
    }
}
