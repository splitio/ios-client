//
//  SplitNameValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

/**
 Returned errors occurred during validation
 */
struct SplitNameValidationError {
    static let someError: Int = 1
}

struct SplitNameValidationWarning {
    static let nameWasTrimmed: Int = 101
}

/**
 A struct implementing Validatable protocol
 inteded to use it for Split validation
 */
struct SplitValidatable: Validatable {
    
    typealias Entity = SplitValidatable
    
    var name: String?
    
    init(name: String?) {
        self.name = name
    }
    
    func isValid<V>(validator: V) -> Bool where V : Validator, V.Entity == Entity {
        return validator.isValidEntity(self)
    }
}

/**
 A validator for Splits name
 */
class SplitNameValidator: Validator {
    
    var error: Int? = nil
    var warnings: [Int] = []
    var messageLogger: ValidationMessageLogger
    
    init(tag: String) {
        self.messageLogger = DefaultValidationMessageLogger(tag: tag)
    }
    
    func isValidEntity(_ entity: SplitValidatable) -> Bool {
        error = SplitNameValidationError.someError
        warnings.removeAll()
        
        if entity.name == nil {
            messageLogger.e("you passed a null split name, split name must be a non-empty string")
            return false
        }
        
        if entity.name!.isEmpty() {
            messageLogger.e("you passed an empty split name, split name must be a non-empty string")
            return false
        }
        
        if entity.name!.trimmingCharacters(in: .whitespacesAndNewlines) != entity.name! {
            messageLogger.w("split name '\(entity.name!)' has extra whitespace, trimming")
            warnings.append(SplitNameValidationWarning.nameWasTrimmed)
        }
        
        error = nil
        return true
    }
}
