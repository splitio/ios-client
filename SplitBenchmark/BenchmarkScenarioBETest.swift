//
//  BenchmarkScenarioBETest.swift
//  SplitBenchmark
//
//  B and E: factory 2's build() starts only after factory 1's ready-from-cache callback fired.
//

import XCTest
@testable import Split

class BenchmarkScenarioBETest: XCTestCase {

    private func driver() -> FakeBenchmarkDriver {
        let driver = FakeBenchmarkDriver()
        driver.readyMode = .delayed(0.05) // a runner that does not wait shows build 2 ahead of ready 1
        return driver
    }

    func test_ordering_factoryOneReadyBeforeFactoryTwoBuild() throws {
        let driver = driver()
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("B"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        let rows = try runner.run()

        let sequence = runner.events.filter { $0.hasPrefix("build:") || $0.hasPrefix("ready:") }
        XCTAssertEqual(sequence, ["build:1:start:main", "build:1:return", "ready:1", "build:2:start:main",
                                  "build:2:return", "ready:2"])
        XCTAssertEqual(driver.specs.map { $0.apiKeyIdentity }, ["keyA", "keyB"])
        XCTAssertNotEqual(driver.specs[0].apiKey, driver.specs[1].apiKey)
        XCTAssertEqual(rows.map { BenchmarkTestFixtures.values($0)["factoryIndex"] }, ["1", "2"])
    }

    func test_ordering_factoryTwoReadyBeforeFactoryOneBuild_scenarioE() throws {
        let driver = driver()
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("E"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        let rows = try runner.run()

        // E is B with the identities reversed: the second API key is built first, and the other waits for it.
        let sequence = runner.events.filter { $0.hasPrefix("build:") || $0.hasPrefix("ready:") }
        XCTAssertEqual(sequence, ["build:1:start:main", "build:1:return", "ready:1", "build:2:start:main",
                                  "build:2:return", "ready:2"])
        XCTAssertEqual(driver.specs.map { $0.apiKeyIdentity }, ["keyB", "keyA"])
        XCTAssertEqual(rows.map { BenchmarkTestFixtures.values($0)["apiKeyIdentity"] }, ["keyB", "keyA"])
        XCTAssertEqual(rows.map { BenchmarkTestFixtures.values($0)["scenario"] }, ["E", "E"])
    }

    func test_bothReadyNs_onBothRows_andPerFactoryT0T11() throws {
        let driver = driver()
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("B"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        let rows = try runner.run()

        let values = rows.map { BenchmarkTestFixtures.values($0) }
        let t0s = try values.map { try XCTUnwrap(UInt64($0["T0"] ?? "")) }
        let t11s = try values.map { try XCTUnwrap(UInt64($0["T11"] ?? "")) }
        XCTAssertLessThan(t0s[0], t11s[0])
        XCTAssertLessThan(t11s[0], t0s[1]) // factory 2 starts after factory 1 became ready
        XCTAssertLessThan(t0s[1], t11s[1])
        let expected = String(t11s[1] - t0s[0])
        XCTAssertEqual(values.map { $0["bothReadyNs"] }, [expected, expected])
    }

    func test_readyTimeout_throwsAndNeverStartsFactoryTwo() throws {
        let driver = FakeBenchmarkDriver()
        driver.readyMode = .manual
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("B"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload(), readyTimeout: 0.05)

        XCTAssertThrowsError(try runner.run()) { error in
            XCTAssertEqual(error as? BenchmarkRunnerError, .readyTimeout(position: 1))
        }
        XCTAssertEqual(driver.specs.count, 1)
    }

    func test_buildFailure_throws() throws {
        let driver = FakeBenchmarkDriver()
        driver.failBuildAtPosition = 1
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("A"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        XCTAssertThrowsError(try runner.run()) { error in
            XCTAssertEqual(error as? BenchmarkRunnerError, .buildFailed(position: 1))
        }
    }
}
