//
//  Validatable.swift
//  Split
//
//  Created by Javier L. Avrudsky on 10/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

protocol Validatable {
    associatedtype Entity where Entity: Validatable
    func isValid<V: Validator>(validator: V) -> Bool where V.Entity == Entity
}
