//
//  ValidationResult.swift
//  Split
//
//  Created by Javier L. Avrudsky on 07/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

enum ValidationError {
    case some
}

enum ValidationWarning {
    case splitNameShouldBeTrimmed
    case trafficTypeNameHasUppercaseChars
}

struct ValidationErrorInfo {
    var error: ValidationError?
    var errorMessage: String?
    var warnings: [ValidationWarning: String] = [:]
    
    init(error: ValidationError, message: String) {
        self.error = error
        self.errorMessage = message
    }
    
    init(warning: ValidationWarning, message: String) {
        self.warnings[warning] = message
    }
    
    var isError: Bool {
        return error != nil
    }
    
    mutating func addWarning(_ warning: ValidationWarning, message: String) {
        self.warnings[warning] = message
    }
    
    func hasWarning(_ warning: ValidationWarning) -> Bool {
        return warnings[warning] != nil
    }
}
