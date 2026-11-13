//
//  BenchmarkBuilderTest.swift
//  SplitBenchmark
//
//  Spec 6.3: one builder per factory, never reused. Uses the real driver on the small fixture, offline.
//

import XCTest
@testable import Split

class BenchmarkBuilderTest: XCTestCase {

    private var scratch: URL!

    override func setUpWithError() throws {
        scratch = FileManager.default.temporaryDirectory.appendingPathComponent("bench_builder_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: scratch)
    }

    private func runScenario(_ name: String) throws -> RealBenchmarkDriver {
        let args = try BenchmarkArguments.parse(["-benchScenario", name, "-benchFixtureSize", "small",
                                                 "-benchLogging", "off"])
        let payload = try BenchmarkPayload.make(arguments: args, scratchDirectory: scratch)
        let driver = RealBenchmarkDriver(arguments: args, payload: payload)
        _ = try BenchmarkScenarioRunner(arguments: args, driver: driver, payload: payload).run()
        return driver
    }

    func test_oneBuilderPerFactory() throws {
        for name in ["B", "C"] {
            let driver = try runScenario(name)

            let builders = driver.builders
            XCTAssertEqual(builders.count, 2, name)
            XCTAssertFalse(builders[0] === builders[1], "\(name) reused one builder for both factories")
        }
    }

    func test_singleFactoryScenario_usesOneBuilder() throws {
        XCTAssertEqual(try runScenario("A").builders.count, 1)
    }
}
