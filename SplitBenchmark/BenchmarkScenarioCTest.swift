//
//  BenchmarkScenarioCTest.swift
//  SplitBenchmark
//
//  C, C2 and C-bg: two factories whose build() calls are not separated by a ready callback.
//

import XCTest
@testable import Split

class BenchmarkScenarioCTest: XCTestCase {

    private func buildEvents(_ runner: BenchmarkScenarioRunner) -> [String] {
        return runner.events.filter { $0.hasPrefix("build:") }
    }

    func test_secondBuildStartsAfterFirstReturns() throws {
        let driver = FakeBenchmarkDriver()
        driver.waitForPeer = [1] // a runner that overlapped the builds would let build 2 start inside build 1
        driver.readyMode = .delayed(0.05)
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("C"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        _ = try runner.run()

        XCTAssertEqual(buildEvents(runner), ["build:1:start:main", "build:1:return", "build:2:start:main",
                                             "build:2:return"])
        XCTAssertEqual(driver.peerStartedWhileInBuild[1], false)
    }

    func test_secondBuildDoesNotWaitForFirstReady() throws {
        let driver = FakeBenchmarkDriver()
        driver.readyMode = .manual
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("C"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            driver.fire(position: 1)
            driver.fire(position: 2)
        }

        _ = try runner.run()

        // Both builds returned before the first ready callback: the second build did not wait for it.
        let firstReady = try XCTUnwrap(runner.events.firstIndex { $0.hasPrefix("ready:") })
        let secondReturn = try XCTUnwrap(runner.events.firstIndex(of: "build:2:return"))
        XCTAssertLessThan(secondReturn, firstReady)
    }

    func test_c_usesTheSameApiKeyForBothFactories() throws {
        let driver = FakeBenchmarkDriver()
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("C"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        _ = try runner.run()

        XCTAssertEqual(driver.specs.count, 2)
        XCTAssertEqual(driver.specs[0].apiKey, driver.specs[1].apiKey)
        XCTAssertEqual(driver.specs.map { $0.apiKeyIdentity }, ["keyA", "keyA"])
    }

    func test_c2_usesTwoDifferentApiKeys() throws {
        let driver = FakeBenchmarkDriver()
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("C2"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        let rows = try runner.run()

        XCTAssertEqual(driver.specs.count, 2)
        XCTAssertNotEqual(driver.specs[0].apiKey, driver.specs[1].apiKey)
        XCTAssertEqual(buildEvents(runner), ["build:1:start:main", "build:1:return", "build:2:start:main",
                                             "build:2:return"])
        XCTAssertEqual(rows.map { BenchmarkTestFixtures.values($0)["scenario"] }, ["C2", "C2"])
        XCTAssertEqual(rows.map { BenchmarkTestFixtures.values($0)["apiKeyIdentity"] }, ["keyA", "keyB"])
    }

    func test_twoFactories_distinctDatabaseNames_forDifferentKeys() {
        let a = SplitDatabaseHelper.databaseName(prefix: "", apiKey: BenchmarkScenarioRunner.apiKeyA)
        let b = SplitDatabaseHelper.databaseName(prefix: "", apiKey: BenchmarkScenarioRunner.apiKeyB)

        XCTAssertNotNil(a)
        XCTAssertNotEqual(a, b)
    }

    func test_cBackground_barrierReleasedBeforeBothBuildStarts() throws {
        let driver = FakeBenchmarkDriver()
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("C-bg"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())
        _ = try runner.run()

        let events = runner.events
        let released = try XCTUnwrap(events.firstIndex(of: "barrier:released"))
        for start in ["build:1:start:bg", "build:2:start:bg"] {
            let index = try XCTUnwrap(events.firstIndex(of: start), start)
            XCTAssertGreaterThan(index, released, start)
        }
    }

    func test_cBackground_bothBuildsStartBeforeEitherReturns_onBackgroundQueues() throws {
        let driver = FakeBenchmarkDriver()
        driver.waitForPeer = [1, 2]
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("C-bg"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        let rows = try runner.run()

        let builds = buildEvents(runner)
        XCTAssertEqual(builds.count, 4)
        XCTAssertEqual(Set(builds.prefix(2)), ["build:1:start:bg", "build:2:start:bg"])
        XCTAssertEqual(Set(builds.suffix(2)), ["build:1:return", "build:2:return"])
        XCTAssertEqual(driver.peerStartedWhileInBuild[1], true)
        XCTAssertEqual(driver.peerStartedWhileInBuild[2], true)
        XCTAssertEqual(rows.map { BenchmarkTestFixtures.values($0)["scenario"] }, ["C-bg", "C-bg"])
        XCTAssertEqual(driver.specs.map { $0.apiKeyIdentity }, ["keyA", "keyA"])
    }

    func test_bothReadyNs_isLatestT11MinusEarliestT0_onBothRows() throws {
        let driver = FakeBenchmarkDriver()
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("C"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        let rows = try runner.run()

        let values = rows.map { BenchmarkTestFixtures.values($0) }
        let t0s = try values.map { try XCTUnwrap(UInt64($0["T0"] ?? "")) }
        let t11s = try values.map { try XCTUnwrap(UInt64($0["T11"] ?? "")) }
        let expected = String(t11s.max()! - t0s.min()!)
        XCTAssertEqual(values.map { $0["bothReadyNs"] }, [expected, expected])
        XCTAssertEqual(values.map { $0["factoryIndex"] }, ["1", "2"])
    }
}
