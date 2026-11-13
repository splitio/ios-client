//
//  BenchmarkArguments.swift
//  SplitBenchmark
//
//  FME-22007: launch-argument contract of the device benchmark. One scenario per process.
//
//  Harness effect: running under `xcodebuild test-without-building` adds XCTest host and debugger cost to
//  every measured interval. `-benchStandalone` marks a run launched from a standalone host (D10 b) that is
//  outside that harness. It is recorded on this struct only and never changes the CSV contract.
//

import Foundation
@testable import Split

enum BenchmarkScenario: String, CaseIterable {
    case a = "A"
    case b = "B"
    case c = "C"
    case c2 = "C2"
    case d = "D"
    case e = "E"
    /// C with the two build() calls issued from two background queues behind a barrier.
    case cBackground = "C-bg"
    /// One factory, payload at 2x and 4x the flag count of the chosen fixture size.
    case stress2x = "stress2x"
    case stress4x = "stress4x"

    /// Flag-count multiplier of the payload; 1 for every non-stress scenario.
    var payloadMultiplier: Int {
        switch self {
        case .stress2x: return 2
        case .stress4x: return 4
        default: return 1
        }
    }
}

enum LoggingVariant: String {
    case on
    case off

    /// Logger level switch: off silences logging, on is verbose.
    var logLevel: LogLevel { self == .on ? .verbose : .none }
    /// The same switch for `SplitClientConfig.logLevel`.
    var configLogLevel: SplitLogLevel { self == .on ? .verbose : .none }
    /// CSV build variant column.
    var buildVariant: String { "logging-\(rawValue)" }
}

/// Which ready-callback API a run uses: `on(event:)` or `addEventListener`.
enum ReadyAPI: String {
    case on
    case listener
}

enum InstallState: String {
    case first
    case relaunch
}

enum BenchmarkArgumentError: Error, Equatable {
    case missingScenario
    case unknownScenario(String)
    case missingValue(flag: String)
    case invalidValue(flag: String, value: String)
}

struct BenchmarkArguments: Equatable {
    var scenario: BenchmarkScenario
    var sha = ""
    var runIndex = 0
    var fixturePath = ""
    /// Fixture size used when no fixture path is given and for the stress multipliers.
    var fixtureSize = FixtureSize.large
    /// CSV output path; nil means Documents/benchmark.csv.
    var csvPath: String?
    /// Base URL for the SDK and events endpoints; nil keeps the offline default (127.0.0.1:1, cache path only).
    var endpoint: String?
    /// Width override for the D5 sweep; nil leaves the decoder width untouched.
    var width: Int?
    var logging = LoggingVariant.on
    var readyAPI = ReadyAPI.on
    var installState = InstallState.relaunch
    var idleGapSeconds = 0.0
    /// Standalone-host launch variant (D10 b). Recorded only, not a CSV column.
    var standalone = false

    var buildVariant: String { logging.buildVariant }

    /// Seam carrying the width override and the mark recorder.
    func makeSeam(markRecorder: (@Sendable (String, UInt64) -> Void)? = nil) -> InternalSeam {
        return InternalSeam(decoderWidth: width, markRecorder: markRecorder)
    }

    static func fromProcess() throws -> BenchmarkArguments {
        return try parse(CommandLine.arguments)
    }

    static func parse(_ arguments: [String]) throws -> BenchmarkArguments {
        var values = [String: String]()
        var standalone = false
        var index = 0
        while index < arguments.count {
            let flag = arguments[index]
            index += 1
            guard flag.hasPrefix("-bench") else { continue }
            if flag == "-benchStandalone" {
                standalone = true
                continue
            }
            guard index < arguments.count else { throw BenchmarkArgumentError.missingValue(flag: flag) }
            values[flag] = arguments[index]
            index += 1
        }

        guard let scenarioText = values["-benchScenario"] else { throw BenchmarkArgumentError.missingScenario }
        guard let scenario = BenchmarkScenario(rawValue: scenarioText) else {
            throw BenchmarkArgumentError.unknownScenario(scenarioText)
        }
        var result = BenchmarkArguments(scenario: scenario)
        result.standalone = standalone
        result.sha = values["-benchSHA"] ?? ""
        result.fixturePath = values["-benchFixturePath"] ?? ""
        result.csvPath = values["-benchCSVPath"]
        result.endpoint = values["-benchEndpoint"]
        if let text = values["-benchFixtureSize"] {
            guard let value = FixtureSize(rawValue: text) else { throw invalid("-benchFixtureSize", text) }
            result.fixtureSize = value
        }
        if let text = values["-benchRunIndex"] {
            guard let value = Int(text) else { throw invalid("-benchRunIndex", text) }
            result.runIndex = value
        }
        if let text = values["-benchWidth"] {
            guard let value = Int(text) else { throw invalid("-benchWidth", text) }
            result.width = value
        }
        if let text = values["-benchLogging"] {
            guard let value = LoggingVariant(rawValue: text) else { throw invalid("-benchLogging", text) }
            result.logging = value
        }
        if let text = values["-benchReadyAPI"] {
            guard let value = ReadyAPI(rawValue: text) else { throw invalid("-benchReadyAPI", text) }
            result.readyAPI = value
        }
        if let text = values["-benchInstallState"] {
            guard let value = InstallState(rawValue: text) else { throw invalid("-benchInstallState", text) }
            result.installState = value
        }
        if let text = values["-benchIdleGapSeconds"] {
            guard let value = Double(text) else { throw invalid("-benchIdleGapSeconds", text) }
            result.idleGapSeconds = value
        }
        return result
    }

    private static func invalid(_ flag: String, _ value: String) -> BenchmarkArgumentError {
        return .invalidValue(flag: flag, value: value)
    }
}
