//  Copyright © 2025 Split. All rights reserved

import XCTest
@testable import Split

class FallbackSanitizerTests: XCTestCase {
    
    func testValidFlagNames() {
        
        // Happy path
        var fallbackTreatment = FallbackTreatment(treatment: "GLOBAL_DEFAULT")
        var sanitizedTreatment = FallbackSanitizer.sanitize(treatment: fallbackTreatment)
        XCTAssertEqual(sanitizedTreatment?.treatment, "GLOBAL_DEFAULT")
        
        // Non existent flag
        let sanitizedFlagsTreatment = FallbackSanitizer.sanitize(byFlagFallbacks: ["flag" : FallbackTreatment(treatment: "FLAG1_TREATMENT")])
        XCTAssertNil(sanitizedFlagsTreatment["flOg"]?.treatment)
        
        // Name with spaces
        fallbackTreatment = FallbackTreatment(treatment: "GLOBAL DEFAULT")
        sanitizedTreatment = FallbackSanitizer.sanitize(treatment: fallbackTreatment)
        XCTAssertEqual(sanitizedTreatment?.treatment, nil)
        
        // Name too long
        fallbackTreatment = FallbackTreatment(treatment: "GLOBAL_DEFAULTabcdefasdjasdasdkqwi34789efflieru3u298u3alskdjaslkdjaslkdasjdlkasjdaslkdjaslkdjklfliehfo328yrosdhfliwy4lafhlerh83qhlfhlsdhf3qor")
        sanitizedTreatment = FallbackSanitizer.sanitize(treatment: fallbackTreatment)
        XCTAssertEqual(sanitizedTreatment?.treatment, nil)
    }
    
    func testHappyPath() {
        let byFlagFallback = ["flag1" : FallbackTreatment(treatment: "FLAG1_TREATMENT"),
                              "flag2" : FallbackTreatment(treatment: "treatment.23"),
                              "flag3" : FallbackTreatment(treatment: "FLAG3_ TREATMENT"),
                              "flag4" : FallbackTreatment(treatment: "123.treatment")]

        let sanitizedConfig = FallbackSanitizer.sanitize(byFlagFallbacks: byFlagFallback)
        
        XCTAssertEqual(sanitizedConfig.count, 2)
        XCTAssertEqual(sanitizedConfig["flag1"]?.treatment, "FLAG1_TREATMENT")
        XCTAssertEqual(sanitizedConfig["flag4"]?.treatment, "123.treatment")
        XCTAssertNil(sanitizedConfig["flag2"]?.treatment)
    }
    
    func testDescription() {
        let fallbackTreatment = FallbackTreatment(treatment: "FLAG1_TREATMENT", config: "my_config")
        XCTAssertEqual(fallbackTreatment.description, "{\ntreatment: FLAG1_TREATMENT,\nconfig: Optional(\"my_config\"),\nlabel: fallback - \n}")
    }
}
