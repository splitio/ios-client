//
//  SplitChangeValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

/**
 Returned errors occurred during validation
 */
struct SplitChangeValidationError {
    static let someError = 1
}

/**
 A struct implementing Validatable protocol
 inteded to use it for Split change validation
 */
struct SplitChangeValidatable: Validatable {
    
    typealias Entity = SplitChangeValidatable
    
    var splits: [Split]?
    var since: Int64?
    var till: Int64?
    
    init(splitChange: SplitChange) {
        self.splits = splitChange.splits
        self.since = splitChange.since
        self.till = splitChange.till
    }
    
    func isValid<V>(validator: V) -> Bool where V : Validator, Entity == V.Entity {
        return validator.isValidEntity(self)
    }
}

/**
 A validator for Splits Change
 */
class SplitChangeValidator: Validator {
    var error: Int? = nil
    var warnings: [Int] = []
    var messageLogger: ValidationMessageLogger = DefaultValidationMessageLogger(tag: "SplitChangeValidator")
    
    func isValidEntity(_ entity: SplitChangeValidatable) -> Bool {
        error = SplitChangeValidationError.someError
        if !(entity.splits != nil && entity.since != nil && entity.till != nil) {
            messageLogger.w("Split change not valid")
            return false
        }
        error = nil
        return true
    }
}
