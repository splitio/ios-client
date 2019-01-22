//
//  ApiKeyValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

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

class ApiKeyValidator: Validator {
    
    private let tag: String
    let kMaxMatchingKeyLength = ValidationConfig.default.maximumKeyLength
    let kMaxBucketingKeyLength = ValidationConfig.default.maximumKeyLength
    
    init(tag: String) {
        self.tag = tag
    }
    
    func isValidEntity(_ entity: ApiKeyValidatable) -> Bool {
        let apiKey = entity.apiKey
        
        if let key = apiKey  {
            if key.isEmpty() {
                Logger.e("\(tag): you passed and empty api_key, api_key must be a non-empty string")
                return false
            }
        } else {
            Logger.e("\(tag): you passed a null api_key, the api_key must be a non-empty string")
            return false
        }

        return true
    }
}
