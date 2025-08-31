//  Copyright © 2025 Split. All rights reserved

import XCTest
@testable import Split

class FallbackSanitizerTests: XCTestCase {
    
    func testHappyPath() {
        let fallbackConfig = FallbackConfig(global: FallbackTreatment(treatment: "GLOBAL_DEFAULT"),
                                            byFlag: ["flag1" : FallbackTreatment(treatment: "FLAG1_TREATMENT"),
                                                     "flag2" : FallbackTreatment(treatment: "FLAG2_TREATMENT"),
                                                     "flag3" : FallbackTreatment(treatment: "FLAG3_TREATMENT")])

        let sanitizedConfig = FallbackSanitizer.sanitize(fallbackConfig)
        
        XCTAssertEqual(sanitizedConfig.global?.treatment, "GLOBAL_DEFAULT")
        XCTAssertEqual(sanitizedConfig.byFlag["flag2"]?.treatment, "FLAG2_TREATMENT")
        XCTAssertEqual(sanitizedConfig.byFlag["flag3"]?.treatment, "FLAG3_TREATMENT")
    }
    
    func testTooLongGlobal() {
        let fallbackConfig = FallbackConfig(global: FallbackTreatment(treatment: "GLOBAL_DEFAULTabcdefasdjasdasdkqwi34789efflieru3u298u3alskdjaslkdjaslkdasjdlkasjdaslkdjaslkdjklfliehfo328yrosdhfliwy4lafhlerh83qhlfhlsdhf3qor"), byFlag: [:])
        let sanitizedConfig = FallbackSanitizer.sanitize(fallbackConfig)
        
        XCTAssertNil(sanitizedConfig.global?.treatment)
    }
    
    func testInvalidFlagName() {
        // NON EXISTENT FLAG
        var fallbackConfig = FallbackConfig(byFlag: ["flag" : FallbackTreatment(treatment: "FLAG1_TREATMENT")])
        var sanitizedConfig = FallbackSanitizer.sanitize(fallbackConfig)
        XCTAssertNil(sanitizedConfig.byFlag["flOg"]?.treatment)
        
        // WITH SPACES
        fallbackConfig = FallbackConfig(byFlag: ["fla g1" : FallbackTreatment(treatment: "FLAG1_TREATMENT")])
        sanitizedConfig = FallbackSanitizer.sanitize(fallbackConfig)
        XCTAssertNil(sanitizedConfig.byFlag["fla g1"]?.treatment)
        
        // TOO LONG
        fallbackConfig = FallbackConfig(byFlag: ["flag1alskjdalasldjaslkdjaslkdjasdlkasdjlasjdlkdjsaslkdjaslkdjsadlkajdlajdslakdjsaljdllkfhasjlfhaslfash" : FallbackTreatment(treatment: "FLAG1_TREATMENT")])
        sanitizedConfig = FallbackSanitizer.sanitize(fallbackConfig)
        XCTAssertNil(sanitizedConfig.byFlag["flag1alskjdalasldjaslkdjaslkdjasdlkasdjlasjdlkdjsaslkdjaslkdjsadlkajdlajdslakdjsaljdllkfhasjlfhaslfash"]?.treatment)
    }
    
    func testFullSanitize() {
        let validTreatment = FallbackTreatment(treatment: "valid123")
        let invalidTreatment = FallbackTreatment(treatment: "invalid.123")
        let invalidTreatment2 = FallbackTreatment(treatment: "on.off")

        let config = FallbackConfig(
            global: invalidTreatment,
            byFlag: [
                "validFlag": validTreatment,
                "invalid flag": validTreatment,
                "anotherFlag": invalidTreatment2
            ]
        )

        let sanitized = FallbackSanitizer.sanitize(config)

        // Global
        XCTAssertNil(sanitized.global)
        
        // Per flag
        XCTAssertEqual(sanitized.byFlag.count, 1) // Just one flag passed the filters
        XCTAssertEqual(sanitized.byFlag["validFlag"]?.treatment, "valid123")
        XCTAssertNil(sanitized.byFlag["invalid flag"])
        XCTAssertNil(sanitized.byFlag["anotherFlag"])
    }
}
