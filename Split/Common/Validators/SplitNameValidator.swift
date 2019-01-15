//
//  SplitNameValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

class SplitNameValidator: Validator {
    
    private let tag: String
    
    init(tag: String) {
        self.tag = tag
    }
    
    func isValidEntity(_ entity: Split) -> Bool {
        if let splitName = entity.name, splitName.isEmpty() {
            Logger.e("\(tag): key must be a non-empty string")
            return false
        }
        return true
    }
}
