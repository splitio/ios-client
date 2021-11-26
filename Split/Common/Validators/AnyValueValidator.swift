//
//  GenericValueValidator.swift
//  Split
//
//  Created by Javier Avrudsky on 10-Nov-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

protocol AnyValueValidator {
    func isPrimitiveValue(value: Any) -> Bool
    func isList(value: Any) -> Bool
}

struct DefaultAnyValueValidator: AnyValueValidator {
    func isPrimitiveValue(value: Any) -> Bool {
        return !(
            value as? String == nil &&
            value as? Int == nil &&
            value as? Double == nil &&
            value as? Float == nil &&
            value as? Bool == nil)
    }

    func isList(value: Any) -> Bool {
        return !(value as? [String] == nil)
    }
}
