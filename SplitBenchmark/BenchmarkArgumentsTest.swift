//
//  BenchmarkArgumentsTest.swift
//  SplitBenchmark
//

import XCTest
@testable import Split

class BenchmarkArgumentsTest: XCTestCase {

    func test_allFlags_parsed() throws {
        let args = try BenchmarkArguments.parse([
            "/path/to/xctest", "-benchScenario", "C2", "-benchSHA", "abc1234", "-benchRunIndex", "7",
            "-benchFixturePath", "/tmp/fixture_small_22007.json", "-benchWidth", "3", "-benchLogging", "off",
            "-benchReadyAPI", "listener", "-benchInstallState", "first", "-benchIdleGapSeconds", "12.5",
            "-benchStandalone"])

        XCTAssertEqual(args.scenario, .c2)
        XCTAssertEqual(args.sha, "abc1234")
        XCTAssertEqual(args.runIndex, 7)
        XCTAssertEqual(args.fixturePath, "/tmp/fixture_small_22007.json")
        XCTAssertEqual(args.width, 3)
        XCTAssertEqual(args.logging, .off)
        XCTAssertEqual(args.readyAPI, .listener)
        XCTAssertEqual(args.installState, .first)
        XCTAssertEqual(args.idleGapSeconds, 12.5)
        XCTAssertTrue(args.standalone)
        XCTAssertEqual(args.buildVariant, "logging-off")
    }

    func test_defaults_whenOnlyScenarioGiven() throws {
        let args = try BenchmarkArguments.parse(["-benchScenario", "A"])

        XCTAssertEqual(args.scenario, .a)
        XCTAssertEqual(args.sha, "")
        XCTAssertEqual(args.runIndex, 0)
        XCTAssertNil(args.width)
        XCTAssertEqual(args.logging, .on)
        XCTAssertEqual(args.readyAPI, .on)
        XCTAssertEqual(args.installState, .relaunch)
        XCTAssertEqual(args.idleGapSeconds, 0)
        XCTAssertFalse(args.standalone)
        XCTAssertEqual(args.buildVariant, "logging-on")
    }

    func test_everyScenario_accepted() throws {
        for name in ["A", "B", "C", "C2", "D", "E", "C-bg", "stress2x", "stress4x"] {
            XCTAssertEqual(try BenchmarkArguments.parse(["-benchScenario", name]).scenario.rawValue, name)
        }
    }

    func test_payloadMultiplier_perScenario() {
        XCTAssertEqual(BenchmarkScenario.stress2x.payloadMultiplier, 2)
        XCTAssertEqual(BenchmarkScenario.stress4x.payloadMultiplier, 4)
        for scenario in BenchmarkScenario.allCases where scenario != .stress2x && scenario != .stress4x {
            XCTAssertEqual(scenario.payloadMultiplier, 1, scenario.rawValue)
        }
    }

    func test_csvPath_andFixtureSize_parsed_withDefaults() throws {
        let given = try BenchmarkArguments.parse(["-benchScenario", "A", "-benchCSVPath", "/tmp/x.csv",
                                                  "-benchFixtureSize", "small", "-benchEndpoint", "http://h:1"])
        let defaults = try BenchmarkArguments.parse(["-benchScenario", "A"])

        XCTAssertEqual(given.csvPath, "/tmp/x.csv")
        XCTAssertEqual(given.fixtureSize, .small)
        XCTAssertEqual(given.endpoint, "http://h:1")
        XCTAssertNil(defaults.endpoint)
        XCTAssertNil(defaults.csvPath)
        XCTAssertEqual(defaults.fixtureSize, .large)
        XCTAssertThrowsError(try BenchmarkArguments.parse(["-benchScenario", "A", "-benchFixtureSize", "huge"]))
    }

    func test_unknownScenario_throws() {
        XCTAssertThrowsError(try BenchmarkArguments.parse(["-benchScenario", "Z"])) { error in
            XCTAssertEqual(error as? BenchmarkArgumentError, .unknownScenario("Z"))
        }
    }

    func test_lowercaseScenario_throws() {
        XCTAssertThrowsError(try BenchmarkArguments.parse(["-benchScenario", "a"]))
    }

    func test_missingScenario_throws() {
        XCTAssertThrowsError(try BenchmarkArguments.parse(["-benchSHA", "abc"])) { error in
            XCTAssertEqual(error as? BenchmarkArgumentError, .missingScenario)
        }
    }

    func test_invalidValues_throw() {
        let cases: [[String]] = [
            ["-benchLogging", "maybe"], ["-benchReadyAPI", "poll"], ["-benchInstallState", "second"],
            ["-benchRunIndex", "x"], ["-benchWidth", "wide"], ["-benchIdleGapSeconds", "soon"]
        ]
        for extra in cases {
            XCTAssertThrowsError(try BenchmarkArguments.parse(["-benchScenario", "A"] + extra), "\(extra)") { error in
                XCTAssertEqual(error as? BenchmarkArgumentError,
                               .invalidValue(flag: extra[0], value: extra[1]))
            }
        }
    }

    func test_flagWithoutValue_throws() {
        XCTAssertThrowsError(try BenchmarkArguments.parse(["-benchScenario", "A", "-benchSHA"])) { error in
            XCTAssertEqual(error as? BenchmarkArgumentError, .missingValue(flag: "-benchSHA"))
        }
    }

    func test_loggingVariant_mapsToLogLevel() {
        XCTAssertEqual(LoggingVariant.off.logLevel, .none)
        XCTAssertEqual(LoggingVariant.on.logLevel, .verbose)
        XCTAssertEqual(LoggingVariant.off.configLogLevel, .none)
        XCTAssertEqual(LoggingVariant.on.configLogLevel, .verbose)
    }

    func test_width_mapsIntoSeamDecoderWidth() throws {
        let withWidth = try BenchmarkArguments.parse(["-benchScenario", "D", "-benchWidth", "1"])
        let without = try BenchmarkArguments.parse(["-benchScenario", "D"])

        XCTAssertEqual(withWidth.makeSeam().decoderWidth, 1)
        XCTAssertNil(without.makeSeam().decoderWidth)
    }

    func test_seam_carriesMarkRecorder() throws {
        let buffer = StageMarkBuffer()
        let seam = try BenchmarkArguments.parse(["-benchScenario", "A"]).makeSeam(markRecorder: buffer.sink)

        seam.markRecorder?("probe", 5)

        XCTAssertEqual(buffer.marks.map { $0.name }, ["probe"])
    }

    func test_standalone_doesNotChangeCsvColumns() throws {
        XCTAssertFalse(BenchmarkCSVRow.columns.contains { $0.lowercased().contains("standalone") })
    }
}
