import XCTest
@testable import Split

final class RolloutCacheConfigurationTest: XCTestCase {

    func testDefaultValues() throws {
        let config = RolloutCacheConfiguration.builder().build()
        XCTAssertEqual(config.expirationDays, 10)
        XCTAssertFalse(config.clearOnInit)
    }

    func testExpirationIsCorrectlySet() throws {
        let config = RolloutCacheConfiguration.builder().set(expirationDays: 1).build()
        XCTAssertEqual(config.expirationDays, 1)
    }

    func testClearOnInitIsCorrectlySet() throws {
        let config = RolloutCacheConfiguration.builder().set(clearOnInit: true).build()
        XCTAssertTrue(config.clearOnInit)
    }

    func testNegativeExpirationIsSetToDefault() throws {
        let config = RolloutCacheConfiguration.builder().set(expirationDays: -1).build()
        XCTAssertEqual(config.expirationDays, 10)
    }
}
