import XCTest
@testable import Split

final class GeneralInfoStorageTest: XCTestCase {

    private var generalInfoDao: GeneralInfoDaoStub!
    private var generalInfoStorage: GeneralInfoStorage!

    override func setUpWithError() throws {
        generalInfoDao = GeneralInfoDaoStub()
        generalInfoStorage = DefaultGeneralInfoStorage(generalInfoDao: generalInfoDao)
    }

    func testSetUpdateTimestampSetsValueOnDao() throws {
        let timestamp = Int(Date().timeIntervalSince1970).asInt64()
        generalInfoStorage.setUpdateTimestamp(timestamp: timestamp)

        XCTAssertEqual(generalInfoDao.updatedLong, ["splitsUpdateTimestamp": timestamp])
    }

    func testGetUpdateTimestampGetsValueFromDao() throws {
        generalInfoDao.update(info: .splitsUpdateTimestamp, longValue: 1234567)

        XCTAssertEqual(generalInfoStorage.getUpdateTimestamp(), 1234567)
    }

    func testGetUpdateTimestampReturnsZeroIfEntityIsNil() throws {
        XCTAssertEqual(generalInfoStorage.getUpdateTimestamp(), 0)
    }

    func testSetRolloutCacheLastClearTimestampSetsValueOnDao() throws {
        let timestamp = Int(Date().timeIntervalSince1970).asInt64()
        generalInfoStorage.setRolloutCacheLastClearTimestamp(timestamp: timestamp)

        XCTAssertEqual(generalInfoDao.updatedLong, ["rolloutCacheLastClearTimestamp": timestamp])
    }

    func testGetRolloutCacheLastClearTimestampGetsValueFromDao() throws {
        generalInfoDao.update(info: .rolloutCacheLastClearTimestamp, longValue: 1234567)

        XCTAssertEqual(generalInfoStorage.getRolloutCacheLastClearTimestamp(), 1234567)
    }

    func testGetRolloutCacheLastClearTimestampReturnsZeroIfEntityIsNil() throws {
        XCTAssertEqual(generalInfoStorage.getRolloutCacheLastClearTimestamp(), 0)
    }

    func testSetSplitsFilterQueryStringSetsValueOnDao() throws {
        generalInfoStorage.setSplitsFilterQueryString(filterQueryString: "query")

        XCTAssertEqual(generalInfoDao.updatedString, ["splitsFilterQueryString": "query"])
    }

    func testGetSplitsFilterQueryStringGetsValueFromDao() throws {
        generalInfoDao.update(info: .splitsFilterQueryString, stringValue: "query")

        XCTAssertEqual(generalInfoStorage.getSplitsFilterQueryString(), "query")
    }

    func testSetFlagsSpecSetsValueOnDao() throws {
        generalInfoStorage.setFlagSpec(flagsSpec: "2.2")

        XCTAssertEqual(generalInfoDao.updatedString, ["flagsSpec": "2.2"])
    }

    func testGetFlagsSpecGetsValueFromDao() throws {
        generalInfoDao.update(info: .flagsSpec, stringValue: "2.1")

        XCTAssertEqual(generalInfoStorage.getFlagSpec(), "2.1")
    }
}
