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

/**
  Interface to implement when creating an Entity validator
 
  This validation is implementing using the visitor pattern. Entities to be
  validated should implement the Validatable interface, then any Validator implementation
  should "Visit" entity through method isValid(validator) from Validatable and validate it.
 */
protocol Validator {
    associatedtype Entity where Entity: Validatable
    
    /**
      An integer representing the validation error that has occurred
      If no error by convention the value should be 0
     */
    var error: Int? { get }
    
    /**
      List of warnings occurred while validation
      is_valid response should be still true
     */
    var warnings: [Int] { get }
    
    /**
      Allows to set a message logger intended to log validation messages
      This logger has to implement the ValidationMessageLogger protocol
     */
    var messageLogger: ValidationMessageLogger { set get }

    /**
      Validates an entity. Entity should implement Validatable interface
      validation should be short circuit, so it should return false when
      the first error happens
     
     - returns: a boolean indication if entity is valid
     */
    func isValidEntity(_ entity: Entity) -> Bool
}
