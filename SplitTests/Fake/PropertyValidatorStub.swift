//
//  PropertyValidatorStub.swift
//  SplitTests
//
//  Created on 2025-03-26.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation
@testable import Split

class PropertyValidatorStub: PropertyValidator {
    var validateResult: PropertyValidationResult = PropertyValidationResult.valid(properties: nil, sizeInBytes: 0)
    var validateCalled = false
    var lastPropertiesValidated: [String: Any]?
    var lastInitialSizeInBytes: Int = 0
    
    func validate(properties: [String: Any]?, initialSizeInBytes: Int, validationTag: String) -> PropertyValidationResult {
        validateCalled = true
        lastPropertiesValidated = properties
        lastInitialSizeInBytes = initialSizeInBytes
        return validateResult
    }
}
