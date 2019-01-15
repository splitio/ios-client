//
//  SplitChangeValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

class SplitChangeValidator: Validator {
    func isValidEntity(_ entity: SplitChange) -> Bool {
        return entity.splits != nil && entity.since != nil && entity.till != nil
    }
}
