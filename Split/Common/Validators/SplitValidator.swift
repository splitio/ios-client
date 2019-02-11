//
//  SplitNameValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation


/**
 A validator for Splits name
 */

protocol SplitValidator {
    func validate(name: String?) -> ValidationErrorInfo?
}

class DefaultSplitValidator: SplitValidator {
    func validate(name: String?) -> ValidationErrorInfo? {
        
        if name == nil {
            return ValidationErrorInfo(error: .some, message: "you passed a null split name, split name must be a non-empty string")
        }
        
        if name!.isEmpty() {
            return ValidationErrorInfo(error: .some, message: "you passed an empty split name, split name must be a non-empty string")
        }
        
        if name!.trimmingCharacters(in: .whitespacesAndNewlines) != name! {
            return ValidationErrorInfo(warning: .splitNameShouldBeTrimmed, message: "split name '\(name!)' has extra whitespace, trimming")
        }
        
        return nil
    }
}
