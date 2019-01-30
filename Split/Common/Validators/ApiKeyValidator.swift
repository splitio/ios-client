//
//  ApiKeyValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

/**
 Returned errors occurred during validation
 */
struct ApiKeyValidationError {
    static let someError: Int = 1
}

/**
 A struct implementing Validatable protocol
 inteded to use it for validation
 */
struct ApiKeyValidatable: Validatable {
        
    typealias Entity = ApiKeyValidatable
    
    let apiKey: String?
    
    init(apiKey: String?) {
        self.apiKey = apiKey
    }
    
    func isValid<V>(validator: V) -> Bool where V : Validator, V.Entity == Entity {
        return validator.isValidEntity(self)
    }
}

/**
 A validator for Key component
 */
class ApiKeyValidator: Validator {
    
    var error: Int? = nil
    var warnings: [Int] = []
    var messageLogger: ValidationMessageLogger
    
    init(tag: String) {
        self.messageLogger = DefaultValidationMessageLogger(tag: tag)
    }
    
    func isValidEntity(_ entity: ApiKeyValidatable) -> Bool {
        let apiKey = entity.apiKey
        error = ApiKeyValidationError.someError
        
        if let key = apiKey  {
            if key.isEmpty() {
                messageLogger.e("you passed and empty api_key, api_key must be a non-empty string")
                return false
            }
        } else {
            messageLogger.e("you passed a null api_key, the api_key must be a non-empty string")
            return false
        }
        
        error = nil
        return true
    }
}
