//
//  SplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation

public class Key: NSObject, Validatable {
    
    typealias Entity = Key
    
    let matchingKey: String
    let bucketingKey: String?

    public init(matchingKey: String, bucketingKey: String? = nil) {
        self.matchingKey = matchingKey
        self.bucketingKey = bucketingKey
    }
    
    func isValid<V>(validator: V) -> Bool where V : Validator, V.Entity == Entity {
        return validator.isValidEntity(self)
    }
    
}
