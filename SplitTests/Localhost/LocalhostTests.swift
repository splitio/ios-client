//
//  LocalhostTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 15/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split


class LocalhostTests: XCTestCase {


    var bundle: Bundle!
    
    override func setUp() {
        bundle = Bundle(for: type(of: self))
    }
    
    override func tearDown() {
    }
    
    func testUsingYamlFile() {
        let config = SplitClientConfig()
        config.localhostSplitsFileName = "localhost.yaml"
        let factory = LocalhostSplitFactory(key: Key(matchingKey: "key"), config: config, bundle: bundle)
        let client = factory.client
        let manager = factory.manager
        
        let splits = manager.splits
        let sv0 = manager.split(featureName: "split_0")
        let sv1 = manager.split(featureName: "split_1")
        let svx = manager.split(featureName: "x_feature")
        
        let s0Treatment = client.getTreatment("split_0")
        let s0Result = client.getTreatmentWithConfig("split_0")
        
        let s1TreatmentHasKey = client.getTreatment("split_1")
        let s1ResultHasKey = client.getTreatmentWithConfig("split_1")
        
        let xTreatmentKey = client.getTreatment("x_feature")
        let xResultKey = client.getTreatmentWithConfig("x_feature")
        
        let myFeatureTreatmentKey = client.getTreatment("my_feature")
        let myFeatureResultKey = client.getTreatmentWithConfig("my_feature")
        
        let nonExistingTreatment = client.getTreatment("nonExistingTreatment")
        
        let splitNames = ["split_0", "x_feature", "my_feature"]
        let treatments = client.getTreatments(splits: splitNames, attributes: nil)
        let results = client.getTreatmentsWithConfig(splits: splitNames, attributes: nil)
        
        XCTAssertNotNil(factory)
        XCTAssertNotNil(client)
        XCTAssertNotNil(manager)
        
        XCTAssertEqual("off", s0Treatment)
        XCTAssertEqual("off", s0Result.treatment)
        XCTAssertEqual("{ \"size\" : 20 }", s0Result.config)
        
        XCTAssertEqual("control", s1TreatmentHasKey)
        XCTAssertEqual("control", s1ResultHasKey.treatment)
        XCTAssertNil(s1ResultHasKey.config)
        
        XCTAssertEqual("on", xTreatmentKey)
        XCTAssertEqual("on", xResultKey.treatment)
        XCTAssertNil(xResultKey.config)
        
        XCTAssertEqual("red", myFeatureTreatmentKey)
        XCTAssertEqual("red", myFeatureResultKey.treatment)
        XCTAssertNil(myFeatureResultKey.config)
        
        XCTAssertEqual("control", nonExistingTreatment)
        
        XCTAssertEqual(9, splits.count)
        
        XCTAssertNotNil(sv0)
        XCTAssertEqual("off", sv0?.treatments?[0])
        XCTAssertEqual("{ \"size\" : 20 }", sv0?.configs?["off"])
        
        XCTAssertNotNil(sv1)
        XCTAssertEqual("on", sv1?.treatments?[0])
        XCTAssertEqual(0, sv1?.configs?.count)
        
        XCTAssertNotNil(svx)
        XCTAssertNotNil(svx?.treatments?.filter( { $0 == "red" } ))
        XCTAssertNotNil(svx?.treatments?.filter( { $0 == "on" } ))
        XCTAssertNotNil(svx?.treatments?.filter( { $0 == "off" } ))
        XCTAssertNil(svx?.configs?["on"])
        XCTAssertEqual("{\"desc\" : \"this applies only to OFF and only for only_key. The rest will receive ON\"}", svx?.configs?["off"])
        XCTAssertNil(svx?.configs?["red"])
        
        XCTAssertEqual("off", treatments["split_0"])
        XCTAssertEqual("on", treatments["x_feature"])
        XCTAssertEqual("red", treatments["my_feature"])
        
        XCTAssertEqual("off", results["split_0"]?.treatment)
        XCTAssertEqual("{ \"size\" : 20 }", results["split_0"]?.config)
        
        XCTAssertEqual("on", results["x_feature"]?.treatment)
        XCTAssertNil(results["x_feature"]?.config)
        
        XCTAssertEqual("red", results["my_feature"]?.treatment)
        XCTAssertNil(results["my_feature"]?.config)
    }
    
    func testUsingSpaceSeparatedFile() {
        let config = SplitClientConfig()
        config.localhostSplitsFileName = "localhost_legacy.splits"
        let factory = LocalhostSplitFactory(key: Key(matchingKey: "key"), config: config, bundle: bundle)
        let client = factory.client
        let manager = factory.manager
        
        let splits = manager.splits
        let sva = manager.split(featureName: "split_a")
        let svb = manager.split(featureName: "split_b")
        let svd = manager.split(featureName: "split_d")
        
        let saTreatment = client.getTreatment("split_a")
        let saResult = client.getTreatmentWithConfig("split_a")
        
        let sbTreatment = client.getTreatment("split_b")
        let sbResult = client.getTreatmentWithConfig("split_b")
        
        let scTreatment = client.getTreatment("split_c")
        let scResult = client.getTreatmentWithConfig("split_c")
        
        let sdTreatment = client.getTreatment("split_d")
        let sdResult = client.getTreatmentWithConfig("split_d")
        
        let splitNames = ["split_a", "split_b", "split_c"]
        let treatments = client.getTreatments(splits: splitNames, attributes: nil)
        let results = client.getTreatmentsWithConfig(splits: splitNames, attributes: nil)
        
        XCTAssertNotNil(factory)
        XCTAssertNotNil(client)
        XCTAssertNotNil(manager)
        
        XCTAssertEqual("on", saTreatment)
        XCTAssertEqual("on", saResult.treatment)
        XCTAssertNil(saResult.config)
        
        XCTAssertEqual("off", sbTreatment)
        XCTAssertEqual("off", sbResult.treatment)
        XCTAssertNil(sbResult.config)
        
        XCTAssertEqual("red", scTreatment)
        XCTAssertEqual("red", scResult.treatment)
        XCTAssertNil(scResult.config)
        
        XCTAssertEqual("control", sdTreatment)
        XCTAssertEqual("control", sdResult.treatment)
        XCTAssertNil(sdResult.config)
        
        XCTAssertEqual(3, splits.count)
        
        XCTAssertNotNil(sva)
        XCTAssertEqual("on", sva?.treatments?[0])
        XCTAssertEqual(0, sva?.configs?.count)
        
        XCTAssertNotNil(svb)
        XCTAssertEqual("off", svb?.treatments?[0])
        XCTAssertEqual(0, svb?.configs?.count)
        
        XCTAssertNil(svd)
        
        XCTAssertEqual("on", treatments["split_a"])
        XCTAssertEqual("off", treatments["split_b"])
        XCTAssertEqual("red", treatments["split_c"])
        
        XCTAssertEqual("on", results["split_a"]?.treatment)
        XCTAssertEqual("off", results["split_b"]?.treatment)
        XCTAssertEqual("red", results["split_c"]?.treatment)
    }
    
    func testLoadYml() {
        let config = SplitClientConfig()
        config.localhostSplitsFileName = "localhost_yml.yml"
        let factory = LocalhostSplitFactory(key: Key(matchingKey: "key"), config: config, bundle: bundle)
        let client = factory.client
        let t = client.getTreatment("split_0")
        XCTAssertNotNil(factory)
        XCTAssertNotNil(client)
        XCTAssertEqual("off", t)
    }
    
    func testLocalhostFactoryCreation() {
        let factory = DefaultSplitFactoryBuilder().setApiKey("localhost").setMatchingKey("pepe").build() as? LocalhostSplitFactory
        XCTAssertNotNil(factory)
    }
    
    func testDefaultFactoryCreation() {
        let factory = DefaultSplitFactoryBuilder().setApiKey("no_localhost_key").setMatchingKey("pepe").build() as? DefaultSplitFactory
        XCTAssertNotNil(factory)
    }

}
