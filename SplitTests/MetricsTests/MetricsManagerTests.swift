//
//  MetricsManagerTests.swift
//  SplitTests
//
//  Created by Javier on 09/10/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import XCTest
@testable import Split

class MetricsManagerTests: XCTestCase {
    var restClient: MetricsRestClientStub!
    
    override func setUp() {
        restClient = MetricsRestClientStub()
    }

    override func tearDown() {
    }

    func testPushRateNoTimeElapsed() {
        let config = MetricManagerConfig.default
        config.pushRateInSeconds = 100
        let manager = DefaultMetricsManager(config: config, restClient: restClient)
        
        for i in 1...100 {
            manager.time(microseconds: Int64(i), for: "time1")
        }
        XCTAssertNil(restClient.timeMetrics, "Time metrics should be nil")
    }
    
    func testFlush() {
        let config = MetricManagerConfig.default
        config.pushRateInSeconds = 999999
        let manager = DefaultMetricsManager(config: config, restClient: restClient)
        
        for i in 1...100 {
            manager.time(microseconds: Int64(i), for: "time1")
            manager.count(delta: 3, for: "count1")
        }
        manager.flush()
        
        XCTAssertEqual(1, restClient.timeMetrics?.count)
        XCTAssertEqual(1, restClient.counterMetrics?.count)
    }
    
    /***
     *  Metrics manager sends metrics by checking time elapsed since
     *  last post when a new metric is added
     *  This test case is intended to test this feature
     **/
    func testPushRateTimeElapsed() {
        
        let config = MetricManagerConfig.default
        config.pushRateInSeconds = 1
        let manager = DefaultMetricsManager(config: config, restClient: restClient)
        
        manager.time(microseconds: 1, for: "time1")
        manager.time(microseconds: 1, for: "time2")
        XCTAssertNil(restClient.timeMetrics, "Time metrics should be nil")
        
        sleep(1)
        manager.time(microseconds: 1, for: "time3")
        XCTAssertNotNil(restClient.timeMetrics, "Time metrics should not be nil")
        XCTAssertTrue(restClient.timeMetrics!.count == 3, "Time metrics should have 3 elements")
        
        manager.time(microseconds: 1, for: "time1")
        manager.time(microseconds: 1, for: "time2")
        manager.time(microseconds: 1, for: "time3")
        manager.time(microseconds: 1, for: "time4")
        XCTAssertTrue(restClient.timeMetrics!.count == 3, "Time metrics should still have 3 elements because push rate time not elapsed")
        
        sleep(1)
        manager.time(microseconds: 1, for: "time5")
        XCTAssertTrue(restClient.timeMetrics!.count == 5, "Time metrics should have 5 elements")
        
        
        manager.time(microseconds: 1, for: "time1")
        XCTAssertTrue(restClient.timeMetrics!.count == 5, "Time metrics should still have 5 elements because push rate time not elapsed")
        
        sleep(1)
        manager.time(microseconds: 1, for: "time2")
        XCTAssertTrue(restClient.timeMetrics!.count == 2, "Time metrics should have 2 element")
        
        manager.count(delta: 1, for: "counter1")
        manager.count(delta: 1, for: "counter2")
        manager.count(delta: 1, for: "counter3")
        XCTAssertNil(restClient.counterMetrics, "Counter metrics should be nil")
        
        sleep(1)
        manager.count(delta: 1, for: "counter4")
        XCTAssertTrue(restClient.counterMetrics!.count == 4, "Counter metrics should have 4 element")
        
        manager.count(delta: 1, for: "counter1")
        manager.count(delta: 1, for: "counter2")
        XCTAssertTrue(restClient.counterMetrics!.count == 4, "Counter metrics should still have 4 elements because push rate time not elapsed")
        
        sleep(1)
        manager.count(delta: 1, for: "counter3")
        XCTAssertTrue(restClient.counterMetrics!.count == 3, "Counter metrics should have 3 element")
    }
    
    func testTimesOperations() {
        let times: [[String:Int64]] = [
            ["time1":1000477892],
            ["time1": 2216838],
            ["time2": 3325257],
            ["time1": 4987885],
            ["time2": 7481828],
            ["time1": 194620],
            ["time1": 57665],
            ["time1": 4987885],
            ["time2": 7481828],
            ["time1": 11391],
            ["time4": 4987885],
            ["time2": 7481828],
            ["time1": 194620],
            ["time3": 57665],
            ["time4": 4987885],
            ["time2": 7481828],
            ["time3": 11391],
            ["time1": 291929]
        ]
        
        
        let config = MetricManagerConfig.default
        config.pushRateInSeconds = 1
        let manager = DefaultMetricsManager(config: config, restClient: restClient)
        
        for time in times {
            let operation = Array(time.keys)[0]
            let latency = Array(time.values)[0]
            manager.time(microseconds: latency, for: operation)
        }

        sleep(1)
        manager.time(microseconds: 1, for: "time1")
        XCTAssertNotNil(restClient.timeMetrics, "Time metrics should not be nil")
        XCTAssertTrue(restClient.timeMetrics!.count == 4, "Time metrics should have four elements")
        
        let ope = restClient.timeOperations
        XCTAssertTrue(ope.contains("time1") && ope.contains("time2") && ope.contains("time3") && ope.contains("time4"), "Time metrics should have time1-time4 elements")
    }
    
    func testCountersNames() {
        let counters: [[String:Int64]] = [
            ["counter1":1000477892],
            ["counter1": 2216838],
            ["counter2": 3325257],
            ["counter1": 4987885],
            ["counter2": 7481828],
            ["counter1": 194620],
            ["counter1": 57665],
            ["counter1": 4987885],
            ["counter2": 7481828],
            ["counter1": 11391],
            ["counter4": 4987885],
            ["counter2": 7481828],
            ["counter1": 194620],
            ["counter3": 57665],
            ["counter4": 4987885],
            ["counter2": 7481828],
            ["counter3": 11391],
            ["counter1": 291929]
        ]
        
        let config = MetricManagerConfig.default
        config.pushRateInSeconds = 1
        let manager = DefaultMetricsManager(config: config, restClient: restClient)
        
        for counter in counters {
            let counterName = Array(counter.keys)[0]
            let delta = Array(counter.values)[0]
            manager.count(delta: delta, for: counterName)
        }
        
        sleep(1)
        manager.count(delta: 1, for: "counter1")
        XCTAssertNotNil(restClient.counterMetrics, "Count metrics should not be nil")
        XCTAssertTrue(restClient.counterMetrics!.count == 4, "Count metrics should have four elements")
        
        let names = restClient.counterNames
        XCTAssertTrue(names.contains("counter1") && names.contains("counter2") && names.contains("counter3") && names.contains("counter4"), "counter metrics should have counter1-counter4 elements")
    }
    
    func testCounters() {
        
        let results: [String:Int64] = ["counter1": 2, "counter2": 6, "counter3": 40, "counter4": 1]
        let config = MetricManagerConfig.default
        config.pushRateInSeconds = 1
        let manager = DefaultMetricsManager(config: config, restClient: restClient)
        
        manager.count(delta: 1, for: "counter1")
        manager.count(delta: 1, for: "counter1")
        
        manager.count(delta: 2, for: "counter2")
        manager.count(delta: 2, for: "counter2")
        manager.count(delta: 2, for: "counter2")
        
        manager.count(delta: 10, for: "counter3")
        manager.count(delta: 10, for: "counter3")
        manager.count(delta: 10, for: "counter3")
        manager.count(delta: 10, for: "counter3")
        
        sleep(1)
        manager.count(delta: 1, for: "counter4")
        
        let counters = restClient.counterMetrics!
        for counter in counters {
            XCTAssertTrue(results[counter.name] == counter.delta, "Counter \(counter.name) -> Exp: \(results[counter.name]!), value = \(counter.delta))")
        }
    }
}
