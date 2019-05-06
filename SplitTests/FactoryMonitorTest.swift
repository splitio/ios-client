//
//  FactoryMonitorTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 02/05/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class FactoryMonitorTest: XCTestCase {
    
    var monitor: FactoryMonitor!
    
    override func setUp() {
        monitor = DefaultFactoryMonitor()
    }
    
    func testCountLiveFactories() {
        
        var f1: SplitFactory? = SplitFactoryStub(apiKey: "k1")
        let f2: SplitFactory? = SplitFactoryStub(apiKey: "k1")
        var f3: SplitFactory? = SplitFactoryStub(apiKey: "k2")
        var f4: SplitFactory? = SplitFactoryStub(apiKey: "k3")
        let f5: SplitFactory? = SplitFactoryStub(apiKey: "k4")
        let f6: SplitFactory? = SplitFactoryStub(apiKey: "k4")
        var f7: SplitFactory? = SplitFactoryStub(apiKey: "k4")
        
        monitor.register(instance: f1, for: "k1")
        monitor.register(instance: f2, for: "k1")
        monitor.register(instance: f3, for: "k2")
        monitor.register(instance: f4, for: "k3")
        monitor.register(instance: f5, for: "k4")
        monitor.register(instance: f6, for: "k4")
        monitor.register(instance: f7, for: "k4")
        
        XCTAssertEqual(2, monitor.instanceCount(for: "k1"))
        XCTAssertEqual(1, monitor.instanceCount(for: "k2"))
        XCTAssertEqual(1, monitor.instanceCount(for: "k3"))
        XCTAssertEqual(3, monitor.instanceCount(for: "k4"))
    }
    
    func testDeallocatedCountLiveFactories() {
        
        var f1: SplitFactory? = SplitFactoryStub(apiKey: "k1")
        let f2: SplitFactory? = SplitFactoryStub(apiKey: "k1")
        var f3: SplitFactory? = SplitFactoryStub(apiKey: "k2")
        var f4: SplitFactory? = SplitFactoryStub(apiKey: "k3")
        let f5: SplitFactory? = SplitFactoryStub(apiKey: "k4")
        let f6: SplitFactory? = SplitFactoryStub(apiKey: "k4")
        var f7: SplitFactory? = SplitFactoryStub(apiKey: "k4")
        
        monitor.register(instance: f1, for: "k1")
        monitor.register(instance: f2, for: "k1")
        monitor.register(instance: f3, for: "k2")
        monitor.register(instance: f4, for: "k3")
        monitor.register(instance: f5, for: "k4")
        monitor.register(instance: f6, for: "k4")
        monitor.register(instance: f7, for: "k4")
        
        f1 = nil
        f7 = nil
        
        XCTAssertEqual(1, monitor.instanceCount(for: "k1"))
        XCTAssertEqual(1, monitor.instanceCount(for: "k2"))
        XCTAssertEqual(1, monitor.instanceCount(for: "k3"))
        XCTAssertEqual(2, monitor.instanceCount(for: "k4"))
    }
}
