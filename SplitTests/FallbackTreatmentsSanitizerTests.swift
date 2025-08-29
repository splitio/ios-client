//  Copyright © 2025 Split. All rights reserved

import XCTest
@testable import Split

class FallbackSanitizerTests: XCTestCase {
    
    func testHappyPath() {
        let fallbackConfig = FallbackConfig(global: FallbackTreatment("GLOBAL_DEFAULT"),
                                            byFlag: ["flag1" : FallbackTreatment("FLAG1_TREATMENT"),
                                                     "flag2" : FallbackTreatment("FLAG2_TREATMENT"),
                                                     "flag3" : FallbackTreatment("FLAG3_TREATMENT")])
        
        let sanitizedConfig = FallbackSanitizer.sanitize(fallbackConfig)
        
        XCTAssertEqual(sanitizedConfig.global?.treatment, "GLOBAL_DEFAULT")
        XCTAssertEqual(sanitizedConfig.byFlag["flag2"]?.treatment, "FLAG2_TREATMENT")
        XCTAssertEqual(sanitizedConfig.byFlag["flag3"]?.treatment, "FLAG3_TREATMENT")
    }
    
    func testTooLongGlobal() {
        let fallbackConfig = FallbackConfig(global: FallbackTreatment("GLOBAL_DEFAULTabcdefasdjasdasdkqwi34789efflieru3u298u3alskdjaslkdjaslkdasjdlkasjdaslkdjaslkdjklfliehfo328yrosdhfliwy4lafhlerh83qhlfhlsdhf3qor"), byFlag: [:])
        
        let sanitizedConfig = FallbackSanitizer.sanitize(fallbackConfig)
        
        XCTAssertEqual(sanitizedConfig.global?.treatment, nil)
    }
    
    func testInvalidFlagName() {
        // NON EXISTENT FLAG
        var fallbackConfig = FallbackConfig(byFlag: ["flag" : FallbackTreatment("FLAG1_TREATMENT")])
        var sanitizedConfig = FallbackSanitizer.sanitize(fallbackConfig)
        XCTAssertEqual(sanitizedConfig.byFlag["flOg"]?.treatment, nil)
        
        // NAME WITH SPACES
        fallbackConfig = FallbackConfig(byFlag: ["fla g1" : FallbackTreatment("FLAG1_TREATMENT")])
        sanitizedConfig = FallbackSanitizer.sanitize(fallbackConfig)
        XCTAssertEqual(sanitizedConfig.byFlag["fla g1"]?.treatment, nil)
        
        // NAME TOO LONG
        fallbackConfig = FallbackConfig(byFlag: ["flag1alskjdalasldjaslkdjaslkdjasdlkasdjlasjdlkdjsaslkdjaslkdjsadlkajdlajdslakdjsaljdllkfhasjlfhaslfash" : FallbackTreatment("FLAG1_TREATMENT")])
        sanitizedConfig = FallbackSanitizer.sanitize(fallbackConfig)
        XCTAssertEqual(sanitizedConfig.byFlag["flag1alskjdalasldjaslkdjaslkdjasdlkasdjlasjdlkdjsaslkdjaslkdjsadlkajdlajdslakdjsaljdllkfhasjlfhaslfash"]?.treatment, nil)
    }
}
