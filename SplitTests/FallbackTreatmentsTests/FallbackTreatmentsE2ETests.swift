//  Created by Martin Cardozo on 05/09/2025

import XCTest
@testable import Split

class FallbackTreatmentsE2ETests: XCTestCase {
    
    func test__NoFallback() {

        // Clients setup
        let factory = IntegrationHelper().simplestFactoryWithDummyKeys().build()
        let client  = factory!.client
        let client2 = factory!.client(key: Key(matchingKey: "key2"))
        
        // Wait for ready
        let readyClient = XCTestExpectation()
        client.on(event: .sdkReady) {
            readyClient.fulfill()
        }
        let readyClient2 = XCTestExpectation()
        client2.on(event: .sdkReady) {
            readyClient2.fulfill()
        }
        wait(for: [readyClient, readyClient2], timeout: 5)
        
        // Eval
        let treatment  = client.getTreatment("non_existent_flag")
        let treatment2 = client2.getTreatment("non_existent_flag2")
        
        XCTAssertEqual(treatment,  SplitConstants.control)
        XCTAssertEqual(treatment2, SplitConstants.control)
    }
    
    func test__GlobalFallback() {
        
        // Fallback setup
        let fallbackTreatment = "GLOBAL_TREATMENT"
        let fallbackConfiguration = FallbackTreatmentsConfig.builder()
            .global(fallbackTreatment)
            .build()
        
        // Clients setup
        let config = SplitClientConfig()
        config.fallbackTreatments = fallbackConfiguration
        let factory = IntegrationHelper().simplestFactoryWithDummyKeys()
            .setConfig(config)
            .build()
        let client  = factory!.client
        let client2 = factory!.client(key: Key(matchingKey: "key2"))
        
        // Wait for ready
        let readyClient = XCTestExpectation()
        client.on(event: .sdkReady) {
            readyClient.fulfill()
        }
        let readyClient2 = XCTestExpectation()
        client2.on(event: .sdkReady) {
            readyClient2.fulfill()
        }
        wait(for: [readyClient, readyClient2], timeout: 5)
        
        // Eval
        let treatment  = client.getTreatment("non_existent_flag")
        let treatment2 = client2.getTreatment("non_existent_flag2")
        
        XCTAssertEqual(treatment,  fallbackTreatment)
        XCTAssertEqual(treatment2, fallbackTreatment)
    }
    
    func test__FlagFallback() {
        
        // Fallback setup
        let fallbackTreatment = "FLAG_TREATMENT"
        let fallbackConfiguration = FallbackTreatmentsConfig.builder()
            .byFlag(["non_existent_flag": fallbackTreatment])
            .build()
        
        // Clients setup
        let config = SplitClientConfig()
        config.fallbackTreatments = fallbackConfiguration
        let factory = IntegrationHelper().simplestFactoryWithDummyKeys()
            .setConfig(config)
            .build()
        let client  = factory!.client
        let client2 = factory!.client(key: Key(matchingKey: "key2"))
        
        // Eval before ready
        let treatment3 = client.getTreatment("non_existent_flag")
        let treatment4 = client.getTreatment("non_existent_flag2")
        XCTAssertEqual(treatment3, fallbackTreatment)
        XCTAssertEqual(treatment4, "control")
        
        // Wait for ready
        let readyClient = XCTestExpectation()
        client.on(event: .sdkReady) {
            readyClient.fulfill()
        }
        let readyClient2 = XCTestExpectation()
        client2.on(event: .sdkReady) {
            readyClient2.fulfill()
        }
        wait(for: [readyClient, readyClient2], timeout: 5)
        
        // Eval
        let treatment  = client.getTreatment("non_existent_flag")
        let treatment2 = client2.getTreatment("non_existent_flag2")
        
        XCTAssertEqual(treatment, fallbackTreatment)
        XCTAssertEqual(treatment2, SplitConstants.control)
    }
    
    func test__FlagOverridesGlobal() {

        // Fallback setup
        let globalFallback = "GLOBAL_FALLBACK"
        let flagFallback   = "FLAG_FALLBACK"
        let flagToOverride = "my_flag"
        let fallbackConfiguration = FallbackTreatmentsConfig.builder()
            .global(globalFallback)
            .byFlag([flagToOverride: flagFallback])
            .build()
        
        // Clients setup
        let config = SplitClientConfig()
        config.fallbackTreatments = fallbackConfiguration
        let factory = IntegrationHelper().simplestFactoryWithDummyKeys()
            .setConfig(config)
            .build()
        let client  = factory!.client
        let client2 = factory!.client(key: Key(matchingKey: "key2"))
        
        // Wait for ready
        let readyClient = XCTestExpectation()
        client.on(event: .sdkReady) {
            readyClient.fulfill()
        }
        let readyClient2 = XCTestExpectation()
        client2.on(event: .sdkReady) {
            readyClient2.fulfill()
        }
        wait(for: [readyClient, readyClient2], timeout: 5)
        
        // Eval
        let treatment  = client.getTreatment("non_existent_flag")
        let treatment2 = client2.getTreatment(flagToOverride)
        
        XCTAssertEqual(treatment, globalFallback)
        XCTAssertEqual(treatment2, flagFallback)
    }
    
    func test__OverrideOnlyIfControl() {

        // Fallback setup
        let globalFallback = "GLOBAL_FALLBACK"
        let fallbackConfiguration = FallbackTreatmentsConfig.builder()
            .global(globalFallback)
            .build()
        
        // Client setup
        let config = SplitClientConfig()
        config.fallbackTreatments = fallbackConfiguration
        let factory = IntegrationHelper().simplestFactoryWithDummyKeys()
            .setConfig(config)
            .build()
        let client = factory!.client
        
        // Wait for ready
        let sdkReady = XCTestExpectation()
        client.on(event: .sdkReady) {
            sdkReady.fulfill()
        }
        wait(for: [sdkReady], timeout: 5)
        
        // Eval
        let treatment  = client.getTreatment("FACUNDO_TEST") // From splitchanges_1.json
        let treatment2 = client.getTreatment("non_existent_flag")
        
        XCTAssertEqual(treatment, "off")
        XCTAssertEqual(treatment2, globalFallback)
    }
    
    func test__CorrectImpressionLabel() {
        
        // Fallback setup
        let flagToOverride = "benchmark_jw_1" // From splitchanges_1.json
        let flagFallback   = "FLAG_FALLBACK"
        
        let fallbackConfiguration = FallbackTreatmentsConfig.builder()
            .byFlag([flagToOverride: flagFallback])
            .build()
        
        // Client setup
        let config = SplitClientConfig()
        config.fallbackTreatments = fallbackConfiguration
        var impressionsLabels: [String] = []
        config.impressionListener = { impression in
            impressionsLabels.append(impression.label!)
        }
        let factory = IntegrationHelper().simplestFactoryWithDummyKeys()
            .setConfig(config)
            .build()
        let client = factory!.client
        
        let sdkReady = XCTestExpectation()
        client.on(event: .sdkReady) {
            sdkReady.fulfill()
        }
        
        // Eval before ready
        let treatment  = client.getTreatment(flagToOverride)
        let treatment2 = client.getTreatment("testo2222") // From splitchanges_1.json
        XCTAssertEqual(treatment, flagFallback)
        XCTAssertEqual(treatment2, "control")
        
        // Wait for ready
        wait(for: [sdkReady], timeout: 5)
        
        XCTAssertEqual(impressionsLabels, ["fallback - not ready", "not ready"])
    }
    
    func test__CorrectConfigPropagation() {

        // Fallback setup
        let globalTreatment = "GLOBAL_FALLBACK"
        let globalConfig    = "{\"global\":true}"
        let flagTreatment   = "FLAG_FALLBACK"
        let flagConfig      = "{\"flag\":true}"
        let flagToOverride  = "my_flag"
        
        let globalFallback = FallbackTreatment(treatment: globalTreatment, config: globalConfig)
        let flagFallback = FallbackTreatment(treatment: flagTreatment, config: flagConfig)
        let fallbackConfiguration = FallbackTreatmentsConfig.builder()
            .global(globalFallback)
            .byFlag([flagToOverride: flagFallback])
            .build()
        
        // Client setup
        let config = SplitClientConfig()
        config.fallbackTreatments = fallbackConfiguration
        let factory = IntegrationHelper().simplestFactoryWithDummyKeys()
            .setConfig(config)
            .build()
        let client = factory!.client
        
        // Wait for ready
        let sdkReady = XCTestExpectation()
        client.on(event: .sdkReady) {
            sdkReady.fulfill()
        }
        wait(for: [sdkReady], timeout: 5)
        
        // Eval
        let treatment  = client.getTreatmentWithConfig(flagToOverride)
        let treatment2 = client.getTreatmentWithConfig("non_existent_flag")
        
        XCTAssertEqual(treatment.treatment, flagTreatment)
        XCTAssertEqual(treatment.config, flagConfig)
        
        XCTAssertEqual(treatment2.treatment, globalTreatment)
        XCTAssertEqual(treatment2.config, globalConfig)
    }
    
    func test__NonExistentFlagDoesNotGenerateImpression() {

        // Fallback setup
        let globalFallback = "GLOBAL_FALLBACK"
        let fallbackConfiguration = FallbackTreatmentsConfig.builder()
            .global(globalFallback)
            .build()
        
        // Client setup
        let config = SplitClientConfig()
        var impressions: [String] = []
        config.impressionListener = {
            impression in impressions.append(impression.label!)
        }
        config.fallbackTreatments = fallbackConfiguration
        let factory = IntegrationHelper().simplestFactoryWithDummyKeys()
            .setConfig(config)
            .build()
        let client = factory!.client
        
        // Wait for ready
        let sdkReady = XCTestExpectation()
        client.on(event: .sdkReady) {
            sdkReady.fulfill()
        }
        wait(for: [sdkReady], timeout: 5)
        
        // Eval
        let treatment = client.getTreatment("non_existent_flag")
        XCTAssertEqual(treatment, globalFallback)
        let treatment2 = client.getTreatment("testo2222") // From splitchanges_1.json
        XCTAssertEqual(treatment2, "on")
        XCTAssertEqual(impressions.count, 1, "Should record just real flags impressions")
    }
}
