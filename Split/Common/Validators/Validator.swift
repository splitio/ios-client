//
//  Validator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 10/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

class ValidationError: Error {
}

protocol Validator {
    associatedtype Entity where Entity: Validatable
    var error: Int? { get }
    var warnings: [Int] { get }
    var messageLogger: ValidationMessageLogger { set get }

    func isValidEntity(_ entity: Entity) -> Bool
}
