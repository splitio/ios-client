//
//  KeyValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

/**
 Returned errors occurred during validation
 */
struct KeyValidationError {
    static let nullMatchingKey: Int = 1
    static let emptyMatchingKey: Int = 2
    static let longMatchingKey: Int = 3
    static let emptyBucketingkey: Int = 4
    static let longBucketingKey: Int = 5
}

/**
 A struct similar to Key class implementing Validatable protocol
 and allowing null values so that is possible
 use it for validation
 */
struct KeyValidatable: Validatable {
        
    typealias Entity = KeyValidatable
    
    let matchingKey: String?
    let bucketingKey: String?
    
    init(matchingKey: String?) {
        self.init(matchingKey: matchingKey, bucketingKey: nil)
    }
    
    init(matchingKey: String?, bucketingKey: String? = nil) {
        self.matchingKey = matchingKey
        self.bucketingKey = bucketingKey
    }
    
    init(key: Key) {
        self.matchingKey = key.matchingKey
        self.bucketingKey = key.bucketingKey
    }
    
    func isValid<V>(validator: V) -> Bool where V : Validator, V.Entity == Entity {
        return validator.isValidEntity(self)
    }
}

/**
 A validator for Key component
 */
class KeyValidator: Validator {
    
    var error: Int? = nil
    var warnings: [Int] = []
    var messageLogger: ValidationMessageLogger
    
    let kMaxMatchingKeyLength = ValidationConfig.default.maximumKeyLength
    let kMaxBucketingKeyLength = ValidationConfig.default.maximumKeyLength
    
    init(tag: String) {
        self.messageLogger = DefaultValidationMessageLogger(tag: tag)
    }
    
    func isValidEntity(_ entity: KeyValidatable) -> Bool {
        let matchingKey = entity.matchingKey
        let bucketingKey = entity.bucketingKey
        
        if let key = matchingKey  {
            if key.isEmpty() {
                messageLogger.e("you passed an empty string, matching key must a non-empty string")
                error = KeyValidationError.emptyMatchingKey
                return false
            }
            
            if key.count > kMaxMatchingKeyLength {
                messageLogger.e("matching key too long - must be \(kMaxMatchingKeyLength) characters or less")
                error = KeyValidationError.longMatchingKey
                return false
            }
        } else {
            messageLogger.e("you passed a null key, the key must be a non-empty string")
            error = KeyValidationError.nullMatchingKey
            return false
        }

        if let key = bucketingKey {
            if key.isEmpty() {
                messageLogger.e("you passed an empty string, bucketing key must be be null or a non-empty string")
                error = KeyValidationError.emptyBucketingkey
                return false
            }
            
            if key.count > kMaxBucketingKeyLength {
                messageLogger.e("bucketing key too long - must be \(kMaxBucketingKeyLength) characters or less")
                error = KeyValidationError.longBucketingKey
                return false
            }
        }
        error = nil
        return true
    }
}
