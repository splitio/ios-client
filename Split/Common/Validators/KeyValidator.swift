//
//  KeyValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

class KeyValidator: Validator {
    
    private let tag: String
    let kMaxMatchingKeyLength = 250
    
    init(tag: String) {
        self.tag = tag
    }
    
    func isValidEntity(_ entity: Key) -> Bool {
        let matchingKey = entity.matchingKey
        if matchingKey.isEmpty() {
            Logger.e("\(tag): you passed \"\", key must be a non-empty string")
            return false
        }
        
        if matchingKey.count > kMaxMatchingKeyLength {
            Logger.e("\(tag): key too long - must be \(kMaxMatchingKeyLength) characters or less")
            return false
        }
        return true
    }
}
