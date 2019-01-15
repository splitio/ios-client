//
//  Validator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 10/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

protocol Validator {
    associatedtype Entity where Entity: Validatable
    func isValidEntity(_ entity: Entity) -> Bool
}
