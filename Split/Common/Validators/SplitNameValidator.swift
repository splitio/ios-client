//
//  SplitNameValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

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

class SplitNameValidator: Validator {
    
    private let tag: String
    
    init(tag: String) {
        self.tag = tag
    }
    
    func isValidEntity(_ entity: SplitValidatable) -> Bool {
        
        if entity.name == nil {
            Logger.e("\(tag): you passed a null split name, split name must be a non-empty string")
            return false
        }
        
        if entity.name!.isEmpty() {
            Logger.e("\(tag): you passed an empty split name, split name must be a non-empty string")
            return false
        }
        return true
    }
}
