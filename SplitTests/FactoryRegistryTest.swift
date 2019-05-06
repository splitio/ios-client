//
//  FactoryRegistryTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 02/05/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split


class FactoryRegistryTest: XCTestCase {
    
    var registry: FactoryRegistry!
    
    override func setUp() {
        registry = FactoryRegistry()
    }
    
    func testCountLiveFactories() {
        
        var f1: SplitFactory? = SplitFactoryStub(apiKey: "k1")
        let f2: SplitFactory? = SplitFactoryStub(apiKey: "k1")
        var f3: SplitFactory? = SplitFactoryStub(apiKey: "k2")
        var f4: SplitFactory? = SplitFactoryStub(apiKey: "k3")
        let f5: SplitFactory? = SplitFactoryStub(apiKey: "k4")
        let f6: SplitFactory? = SplitFactoryStub(apiKey: "k4")
        var f7: SplitFactory? = SplitFactoryStub(apiKey: "k4")
        
        var wf1: WeakFactory = WeakFactory(factory: f1)
        let wf2: WeakFactory = WeakFactory(factory: f2)
        var wf3: WeakFactory = WeakFactory(factory: f3)
        let wf4: WeakFactory = WeakFactory(factory: f4)
        let wf5: WeakFactory = WeakFactory(factory: f5)
        var wf6: WeakFactory = WeakFactory(factory: f6)
        var wf7: WeakFactory = WeakFactory(factory: f7)
        
        registry.append(wf1, to: "k1")
        registry.append(wf2, to: "k1")
        registry.append(wf3, to: "k2")
        registry.append(wf6, to: "k4")
        registry.append(wf7, to: "k4")
        registry.append(wf4, to: "k3")
        registry.append(wf5, to: "k4")
        
        XCTAssertEqual(2, registry.count(for: "k1"))
        XCTAssertEqual(1, registry.count(for: "k2"))
        XCTAssertEqual(1, registry.count(for: "k3"))
        XCTAssertEqual(3, registry.count(for: "k4"))
        XCTAssertEqual(7, registry.count)
        
    }
    
    func testCountWithDeallocatedLiveFactories() {
        
        var f1: SplitFactory? = SplitFactoryStub(apiKey: "k1")
        var f2: SplitFactory? = SplitFactoryStub(apiKey: "k1")
        let f3: SplitFactory? = SplitFactoryStub(apiKey: "k2")
        var f4: SplitFactory? = SplitFactoryStub(apiKey: "k3")
        let f5: SplitFactory? = SplitFactoryStub(apiKey: "k4")
        var f6: SplitFactory? = SplitFactoryStub(apiKey: "k4")
        var f7: SplitFactory? = SplitFactoryStub(apiKey: "k4")

        var wf1: WeakFactory = WeakFactory(factory: f1)
        var wf2: WeakFactory = WeakFactory(factory: f2)
        let wf3: WeakFactory = WeakFactory(factory: f3)
        let wf4: WeakFactory = WeakFactory(factory: f4)
        let wf5: WeakFactory = WeakFactory(factory: f5)
        let wf6: WeakFactory = WeakFactory(factory: f6)
        let wf7: WeakFactory = WeakFactory(factory: f7)
        
        registry.append(wf1, to: "k1")
        registry.append(wf2, to: "k1")
        registry.append(wf3, to: "k2")
        registry.append(wf6, to: "k4")
        registry.append(wf7, to: "k4")
        registry.append(wf4, to: "k3")
        registry.append(wf5, to: "k4")
        
        f1 = nil
        f7 = nil
        
        XCTAssertEqual(1, registry.count(for: "k1"))
        XCTAssertEqual(1, registry.count(for: "k2"))
        XCTAssertEqual(1, registry.count(for: "k3"))
        XCTAssertEqual(2, registry.count(for: "k4"))
        XCTAssertEqual(5, registry.count)
        
    }
}


