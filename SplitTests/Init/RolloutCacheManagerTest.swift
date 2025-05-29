@testable import Split
import XCTest

final class RolloutCacheManagerTest: XCTestCase {
    private var rolloutCacheManager: RolloutCacheManager!
    private var splitsStorage: SplitsStorageStub!
    private var segmentsStorage: MySegmentsStorageStub!
    private var generalInfoStorage: GeneralInfoStorageMock!

    override func setUpWithError() throws {
        splitsStorage = SplitsStorageStub()
        segmentsStorage = MySegmentsStorageStub()
        generalInfoStorage = GeneralInfoStorageMock()
    }

    func testValidateCacheCallsListener() throws {
        rolloutCacheManager = getCacheManager(expiration: 10)

        let result = validateCache()

        XCTAssertTrue(result)
    }

    func testValidateCacheCallsClearOnStoragesWhenExpirationIsSurpassed() throws {
        rolloutCacheManager = getCacheManager(expiration: 9)
        generalInfoStorage.setUpdateTimestamp(timestamp: getTimestamp(plusDays: -10))

        let result = validateCache()

        XCTAssertTrue(result)
        XCTAssertTrue(splitsStorage.clearCalled)
        XCTAssertTrue(segmentsStorage.clearCalled)
    }

    func testValidateCacheDoesNotCallClearOnStoragesWhenExpirationIsNotSurpassedAndClearOnInitIsFalse() throws {
        rolloutCacheManager = getCacheManager(expiration: 10)
        generalInfoStorage.setUpdateTimestamp(timestamp: getTimestamp(plusDays: -1))

        let result = validateCache()

        XCTAssertTrue(result)
        XCTAssertFalse(splitsStorage.clearCalled)
        XCTAssertFalse(segmentsStorage.clearCalled)
    }

    func testValidateCacheCallsClearOnStoragesWhenExpirationIsNotSurpassedAndClearOnInitIsTrue() throws {
        rolloutCacheManager = getCacheManager(expiration: 10, clearOnInit: true)
        generalInfoStorage.setUpdateTimestamp(timestamp: getTimestamp(plusDays: -1))

        let result = validateCache()

        XCTAssertTrue(result)
        XCTAssertTrue(splitsStorage.clearCalled)
        XCTAssertTrue(segmentsStorage.clearCalled)
    }

    func testValidateCacheCallsClearOnStorageOnlyOnceWhenExecutedConsecutively() throws {
        rolloutCacheManager = getCacheManager(expiration: 10, clearOnInit: true)
        generalInfoStorage.setUpdateTimestamp(timestamp: getTimestamp(plusDays: -1))

        let clearCalledTimes = segmentsStorage.clearCalledTimes
        let result = validateCache()
        let result2 = validateCache()

        XCTAssertTrue(result)
        XCTAssertTrue(result2)
        XCTAssertEqual(clearCalledTimes, 0)
        XCTAssertEqual(splitsStorage.clearCalledTimes, 1)
        XCTAssertEqual(segmentsStorage.clearCalledTimes, 1)
    }

    func testValidateCacheUpdatesLastClearTimestampWhenStoragesAreCleared() throws {
        rolloutCacheManager = getCacheManager(expiration: 10, clearOnInit: true)
        generalInfoStorage.setUpdateTimestamp(timestamp: getTimestamp(plusDays: -1))
        let initialLastClearTimestamp = generalInfoStorage.getRolloutCacheLastClearTimestamp()

        let result = validateCache()

        XCTAssertTrue(result)
        XCTAssertEqual(splitsStorage.clearCalledTimes, 1)
        XCTAssertEqual(segmentsStorage.clearCalledTimes, 1)
        XCTAssertGreaterThan(generalInfoStorage.getRolloutCacheLastClearTimestamp(), initialLastClearTimestamp)
    }

    func testValidateCacheDoesNotUpdateLastClearTimestampWhenStoragesAreNotCleared() throws {
        rolloutCacheManager = getCacheManager(expiration: 10)
        let updateTimestamp = getTimestamp(plusDays: -1)
        generalInfoStorage.setUpdateTimestamp(timestamp: updateTimestamp)
        generalInfoStorage.rolloutCacheLastClearTimestamp = 123456

        let result = validateCache()

        XCTAssertTrue(result)
        XCTAssertFalse(splitsStorage.clearCalled)
        XCTAssertFalse(segmentsStorage.clearCalled)
        XCTAssertEqual(generalInfoStorage.getRolloutCacheLastClearTimestamp(), 123456)
    }

    func testDefaultValueForUpdateTimestampDoesNotClearCache() throws {
        rolloutCacheManager = getCacheManager(expiration: 10)
        let result = validateCache()

        XCTAssertTrue(result)
        XCTAssertFalse(splitsStorage.clearCalled)
        XCTAssertFalse(segmentsStorage.clearCalled)
    }

    func testDefaultValueForLastClearTimestampClearsCacheWhenClearOnInitIsTrue() throws {
        rolloutCacheManager = getCacheManager(expiration: 10, clearOnInit: true)
        let result = validateCache()

        XCTAssertTrue(result)
        XCTAssertEqual(splitsStorage.clearCalledTimes, 1)
        XCTAssertEqual(segmentsStorage.clearCalledTimes, 1)
    }

    private func getCacheManager(expiration: Int, clearOnInit: Bool = false) -> RolloutCacheManager {
        return DefaultRolloutCacheManager(
            generalInfoStorage: generalInfoStorage,
            rolloutCacheConfiguration: RolloutCacheConfiguration.builder()
                .set(expirationDays: expiration)
                .set(clearOnInit: clearOnInit)
                .build(),
            storages: splitsStorage, segmentsStorage)
    }

    private func getTimestamp(plusDays: Int) -> Int64 {
        return Date.now() + Int64(plusDays * 86400)
    }

    /// Runs validate cache and waits for it to finish
    /// Returns true if it was successful
    private func validateCache() -> Bool {
        let latch = DispatchSemaphore(value: 0)
        rolloutCacheManager.validateCache {
            latch.signal()
        }

        return latch.wait(timeout: DispatchTime.now() + 5) == .success
    }
}
