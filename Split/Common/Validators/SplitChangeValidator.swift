//
//  SplitChangeValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

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

class SplitChangeValidator: Validator {
    func isValidEntity(_ entity: SplitChangeValidatable) -> Bool {
        return entity.splits != nil && entity.since != nil && entity.till != nil
    }
}
