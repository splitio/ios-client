//
//  BenchmarkScenarioDTest.swift
//  SplitBenchmark
//
//  D (cache-empty), the populate-when-absent rule and the single-factory scenarios.
//

import XCTest
@testable import Split

class BenchmarkScenarioDTest: XCTestCase {

    func test_deleteBeforeMeasure() throws {
        let driver = FakeBenchmarkDriver()
        driver.cachedKeys = [BenchmarkScenarioRunner.apiKeyA]
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("D"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        let rows = try runner.run()

        let deleteIndex = try XCTUnwrap(runner.events.firstIndex(of: "delete:keyA"))
        let buildIndex = try XCTUnwrap(runner.events.firstIndex(of: "build:1:start:main"))
        XCTAssertLessThan(deleteIndex, buildIndex)
        XCTAssertEqual(driver.deletedKeys, [BenchmarkScenarioRunner.apiKeyA])
        let values = BenchmarkTestFixtures.values(try XCTUnwrap(rows.first))
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(values["scenario"], "D")
        XCTAssertEqual(values["deletedBeforeMeasure"], "true")
        XCTAssertEqual(values["populatedThisRun"], "false")
    }

    func test_scenarioD_doesNotPopulateTheCache() throws {
        let driver = FakeBenchmarkDriver()
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("D"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        _ = try runner.run()

        XCTAssertEqual(driver.preparedKeys, [])
        XCTAssertFalse(runner.events.contains { $0.hasPrefix("prepare:") })
    }

    func test_nonD_neverDeletes_andRecordsFalse() throws {
        for name in ["A", "B", "C", "C2", "E", "C-bg", "stress2x", "stress4x"] {
            let driver = FakeBenchmarkDriver()
            let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments(name), driver: driver,
                                                 payload: BenchmarkTestFixtures.payload())

            let rows = try runner.run()

            XCTAssertEqual(driver.deletedKeys, [], name)
            XCTAssertEqual(rows.map { BenchmarkTestFixtures.values($0)["deletedBeforeMeasure"] },
                           Array(repeating: "false", count: rows.count), name)
        }
    }

    func test_absentCache_isPopulatedBeforeFirstBuild_andRecorded() throws {
        let driver = FakeBenchmarkDriver()
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("A"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        let rows = try runner.run()

        let prepare = try XCTUnwrap(runner.events.firstIndex(of: "prepare:keyA:populated"))
        let build = try XCTUnwrap(runner.events.firstIndex(of: "build:1:start:main"))
        XCTAssertLessThan(prepare, build)
        XCTAssertEqual(BenchmarkTestFixtures.values(rows[0])["populatedThisRun"], "true")
    }

    func test_presentCache_isNotPopulated_andRecorded() throws {
        let driver = FakeBenchmarkDriver()
        driver.cachedKeys = [BenchmarkScenarioRunner.apiKeyA]
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("A"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        let rows = try runner.run()

        XCTAssertTrue(runner.events.contains("prepare:keyA:present"))
        XCTAssertEqual(BenchmarkTestFixtures.values(rows[0])["populatedThisRun"], "false")
    }

    func test_twoKeyScenario_populatesBothKeys_populatedIsTrueWhenEitherWas() throws {
        let driver = FakeBenchmarkDriver()
        driver.cachedKeys = [BenchmarkScenarioRunner.apiKeyA]
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("B"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        let rows = try runner.run()

        XCTAssertEqual(Set(driver.preparedKeys), [BenchmarkScenarioRunner.apiKeyA, BenchmarkScenarioRunner.apiKeyB])
        XCTAssertEqual(rows.map { BenchmarkTestFixtures.values($0)["populatedThisRun"] }, ["true", "true"])
    }

    func test_sameKeyScenario_preparesTheKeyOnce() throws {
        let driver = FakeBenchmarkDriver()
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("C"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        _ = try runner.run()

        XCTAssertEqual(driver.preparedKeys, [BenchmarkScenarioRunner.apiKeyA])
    }

    func test_stressScenarios_singleFactory_recordPayloadMultiplier() throws {
        for (name, multiplier) in [("stress2x", 2), ("stress4x", 4), ("A", 1)] {
            let driver = FakeBenchmarkDriver()
            let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments(name), driver: driver,
                                                 payload: BenchmarkTestFixtures.payload(multiplier: multiplier))

            let rows = try runner.run()

            XCTAssertEqual(rows.count, 1, name)
            let values = BenchmarkTestFixtures.values(rows[0])
            XCTAssertEqual(values["scenario"], name)
            XCTAssertEqual(values["payloadMultiplier"], String(multiplier), name)
            XCTAssertEqual(values["bothReadyNs"], "", name)
            XCTAssertEqual(values["factoryIndex"], "1", name)
        }
    }

    func test_t8ToFire_isT11MinusT8Mark() throws {
        let driver = FakeBenchmarkDriver()
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("A"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())
        // Fake clock: prepare does not tick it; T0 reads 1_010 (thermal and wall clock do not tick), T11 1_020.
        driver.marksByPosition[1] = [("T8 splitsLoadedFromCache notified", 1_013)]

        let rows = try runner.run()

        let values = BenchmarkTestFixtures.values(rows[0])
        XCTAssertEqual(values["T0"], "1010")
        XCTAssertEqual(values["T11"], "1020")
        XCTAssertEqual(values["T8"], "1013")
        XCTAssertEqual(values["t8ToFireNs"], "7")
    }

    func test_t8ToFire_isEmptyWhenMarkMissing() throws {
        let driver = FakeBenchmarkDriver()
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("A"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        let rows = try runner.run()

        XCTAssertEqual(BenchmarkTestFixtures.values(rows[0])["t8ToFireNs"], "")
    }

    func test_thermalState_beforeAndAfter_onEveryRow() throws {
        let driver = FakeBenchmarkDriver()
        driver.thermal = [.fair, .serious]
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("B"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        let rows = try runner.run()

        for row in rows {
            let values = BenchmarkTestFixtures.values(row)
            XCTAssertEqual(values["thermalStateBefore"], "fair")
            XCTAssertEqual(values["thermalStateAfter"], "serious")
        }
        XCTAssertEqual(driver.thermalReadCount, 2)
    }

    func test_pinnedReadyAPI_isPassedToTheDriver_andRecorded() throws {
        for api in ["on", "listener"] {
            let driver = FakeBenchmarkDriver()
            let args = try BenchmarkTestFixtures.arguments("A", extra: ["-benchReadyAPI", api])
            let runner = BenchmarkScenarioRunner(arguments: args, driver: driver,
                                                 payload: BenchmarkTestFixtures.payload())

            let rows = try runner.run()

            XCTAssertEqual(driver.readyAPIs.map { $0.rawValue }, [api])
            XCTAssertEqual(BenchmarkTestFixtures.values(rows[0])["readyAPI"], api)
        }
    }

    func test_rowCarriesPayloadAggregates_andWallClock() throws {
        let driver = FakeBenchmarkDriver()
        let runner = BenchmarkScenarioRunner(arguments: try BenchmarkTestFixtures.arguments("A"), driver: driver,
                                             payload: BenchmarkTestFixtures.payload())

        let rows = try runner.run()

        let values = BenchmarkTestFixtures.values(rows[0])
        XCTAssertEqual(values["fixtureSeed"], "22007")
        XCTAssertEqual(values["fixtureHash"], "feedface")
        XCTAssertEqual(values["wallClockStart"], "2023-11-14T22:13:20.000Z")
        XCTAssertEqual(driver.shutdownCalls, 1)
    }
}
