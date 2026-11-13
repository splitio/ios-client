//
//  BenchmarkDirectLaunch.swift
//  SplitBenchmarkHost
//
//  FME-22007 issue 42: the decision and the run for a direct launch of the host app. Pure decision logic is
//  separate from the run so it can be unit tested. Does not import XCTest. Compiled into the host app and
//  into the SplitBenchmark test bundle (shared file) so the bundle can test it.
//

import Foundation

enum BenchmarkDirectLaunch {

    /// Process arguments plus the space separated `BENCH_ARGS` environment variable.
    static func resolveArguments(commandLine: [String] = CommandLine.arguments,
                                 environment: [String: String] = ProcessInfo.processInfo.environment) -> [String] {
        let fromEnvironment = environment["BENCH_ARGS"]?.split(separator: " ").map(String.init) ?? []
        return commandLine + fromEnvironment
    }

    /// True only when `-benchScenario` is present and the process is not running as a test host under xctest.
    static func shouldRun(arguments: [String],
                          environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        guard environment["XCTestConfigurationFilePath"] == nil else { return false }
        return arguments.contains("-benchScenario")
    }

    /// Runs on a background queue, prints `BENCH_CSV_PATH=<path>` then `BENCH_DONE`, or `BENCH_ERROR=<msg>`.
    static func startIfRequested(arguments: [String] = resolveArguments(),
                                 environment: [String: String] = ProcessInfo.processInfo.environment) {
        guard shouldRun(arguments: arguments, environment: environment) else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let parsed = try BenchmarkArguments.parse(arguments)
                let csvURL = BenchmarkRunner.csvURL(for: parsed)
                print("BENCH_CSV_PATH=\(csvURL.path)")
                try BenchmarkRunner.run(arguments: parsed, csvURL: csvURL)
                print("BENCH_DONE")
            } catch {
                print("BENCH_ERROR=\(error)")
            }
        }
    }
}
