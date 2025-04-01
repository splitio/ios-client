//
//  AnyValueValidatorStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class AnyValueValidatorStub: AnyValueValidator {
    var isListResult = true
    var isPrimitiveValueResult = true
    var lastValueChecked: Any?

    func isList(value: Any) -> Bool {
        lastValueChecked = value
        return isListResult
    }

    func isPrimitiveValue(value: Any) -> Bool {
        lastValueChecked = value
        return isPrimitiveValueResult
    }
}
