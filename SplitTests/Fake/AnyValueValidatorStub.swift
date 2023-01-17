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
    func isList(value: Any) -> Bool {
        return true
    }

    func isPrimitiveValue(value: Any) -> Bool {
        return true
    }
}
