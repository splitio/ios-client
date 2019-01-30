//
//  Validatable.swift
//  Split
//
//  Created by Javier L. Avrudsky on 10/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation


/**
  This protocol must be implemented to make an object suitable to validate
  using an implementation of Validator protocol
 */
protocol Validatable {
    associatedtype Entity where Entity: Validatable
    
    /**
     - parameter validator: The validator to validate the current instance.
     - returns: a boolean indicating if instance is valid
     */
    func isValid<V: Validator>(validator: V) -> Bool where V.Entity == Entity
}
