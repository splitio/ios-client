//
//  BenchmarkHostTest.swift
//  SplitBenchmark
//
//  The SplitBenchmark bundle runs inside the SplitBenchmarkHost app, and the direct-launch decision is right.
//

import XCTest

class BenchmarkHostTest: XCTestCase {

    func test_bundleRunsInsideTheHostApp() {
        XCTAssertTrue(Bundle.main.bundlePath.hasSuffix(".app"))
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "CFBundlePackageType") as? String, "APPL")
        XCTAssertEqual(Bundle.main.bundleIdentifier, "com.split.framework.SplitBenchmarkHost")
    }

    func test_shouldRun_whenScenarioArgumentPresentAndNotUnderXCTest() {
        XCTAssertTrue(BenchmarkDirectLaunch.shouldRun(arguments: ["app", "-benchScenario", "A"], environment: [:]))
    }

    func test_shouldNotRun_withoutScenarioArgument() {
        XCTAssertFalse(BenchmarkDirectLaunch.shouldRun(arguments: ["app", "-benchRunIndex", "1"], environment: [:]))
    }

    func test_shouldNotRun_underXCTest_evenWithScenarioArgument() {
        XCTAssertFalse(BenchmarkDirectLaunch.shouldRun(
            arguments: ["app", "-benchScenario", "A"],
            environment: ["XCTestConfigurationFilePath": "/tmp/x.xctestconfiguration"]))
    }

    func test_resolveArguments_mergesBenchArgsEnvironment() {
        let resolved = BenchmarkDirectLaunch.resolveArguments(commandLine: ["app"],
                                                              environment: ["BENCH_ARGS": "-benchScenario C2"])
        XCTAssertEqual(resolved, ["app", "-benchScenario", "C2"])
    }
}
