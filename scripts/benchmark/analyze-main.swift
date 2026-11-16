// Command line runner for BenchmarkAnalysis (FME-22007 issue 31). Compiled with SplitTests/Benchmark/BenchmarkAnalysis.swift
// by analyze.sh. It only reads a CSV and prints; it holds no analysis logic of its own.
// usage: analyze <merged-csv> [minRuns]
import Foundation

let args = CommandLine.arguments
guard args.count >= 2, let text = try? String(contentsOfFile: args[1], encoding: .utf8) else {
    FileHandle.standardError.write(Data("usage: analyze <merged-csv> [minRuns]\n".utf8))
    exit(2)
}
var minRuns = BenchmarkAnalysis.defaultMinRuns
if args.count >= 3 {
    guard let value = Int(args[2]), value >= 1 else {
        FileHandle.standardError.write(Data("analyze: minRuns must be a positive integer\n".utf8))
        exit(2)
    }
    minRuns = value
}
do {
    let runs = try BenchmarkAnalysis.parseRuns(text)
    let reports = BenchmarkAnalysisReport.build(runs: runs, minRuns: minRuns)
    print("minRuns=\(minRuns) (spec default \(BenchmarkAnalysis.defaultMinRuns))")
    print(BenchmarkAnalysisReport.summary(reports))
    print("--- R17 distance from the 50 ms aim (median - 50, ms; reported, not gated) ---")
    for report in reports {
        let distance = report.stats.map { String($0.median - 50) } ?? "n/a"
        print("\(report.scenario) / \(report.buildVariant) / \(report.sha): \(distance)")
    }
    print("--- R13 stage medians ---")
    for report in reports {
        for chain in [report.r13.warm, report.r13.cold].compactMap({ $0 }) {
            print("\(report.scenario) / \(report.buildVariant) / \(report.sha) \(chain.chain.rawValue) chain: "
                  + "complete \(chain.completeRunCount)/\(chain.runCount), median total \(chain.medianTotalMs.map { String($0) } ?? "n/a") ms, "
                  + "sum of stage medians \(chain.sumOfStageMedians) ms, tolerance \(chain.toleranceMs) ms, "
                  + (chain.passes ? "pass" : "FAIL"))
            for stage in chain.stages {
                print("    \(stage.name): \(stage.medianMs) ms"
                      + (stage.unresolved ? " (<1 ms, unresolved)" : "")
                      + (stage.share.map { String(format: " share %.3f", $0) } ?? ""))
            }
        }
        if let share = report.decodeShareMedian { print("\(report.scenario) / \(report.buildVariant) decode share median: \(share)") }
        if let drift = report.drift { print("\(report.scenario) / \(report.buildVariant) drift: \(drift.slopeMsPerHour) ms/hour over \(drift.count) runs") }
    }
} catch {
    FileHandle.standardError.write(Data("analyze: \(error)\n".utf8))
    exit(1)
}
