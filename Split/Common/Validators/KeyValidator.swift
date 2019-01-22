//
//  KeyValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

enum KeyValidationError {
    case nullMatchingKey
    case emptyMatchingKey
    case longMatchingKey
    case emptyBucketingkey
    case longBucketingKey
}

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

class KeyValidator: Validator {
    
    private let tag: String
    var error: KeyValidationError? = nil
    let kMaxMatchingKeyLength = ValidationConfig.default.maximumKeyLength
    let kMaxBucketingKeyLength = ValidationConfig.default.maximumKeyLength
    
    init(tag: String) {
        self.tag = tag
    }
    
    func isValidEntity(_ entity: KeyValidatable) -> Bool {
        let matchingKey = entity.matchingKey
        let bucketingKey = entity.bucketingKey
        
        if let key = matchingKey  {
            if key.isEmpty() {
                Logger.e("\(tag): you passed an empty string, matching key must be a non-empty string")
                error = KeyValidationError.emptyMatchingKey
                return false
            }
            
            if key.count > kMaxMatchingKeyLength {
                Logger.e("\(tag): matching key too long - must be \(kMaxMatchingKeyLength) characters or less")
                error = KeyValidationError.longMatchingKey
                return false
            }
        } else {
            Logger.e("\(tag): you passed a null key, the key must be a non-empty string")
            error = KeyValidationError.nullMatchingKey
            return false
        }

        if let key = bucketingKey {
            if key.isEmpty() {
                Logger.e("\(tag): you passed an empty string, bucketing key must be a non-empty string")
                error = KeyValidationError.emptyBucketingkey
                return false
            }
            
            if key.count > kMaxBucketingKeyLength {
                Logger.e("\(tag): bucketing key too long - must be \(kMaxBucketingKeyLength) characters or less")
                error = KeyValidationError.longBucketingKey
                return false
            }
        }
        error = nil
        return true
    }
}
