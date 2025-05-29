//
//  EventValidatorStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class EventValidatorStub: EventValidator {
    func validate(
        key: String?,
        trafficTypeName: String?,
        eventTypeId: String?,
        value: Double?,
        properties: [String: Any]?,
        isSdkReady: Bool) -> ValidationErrorInfo? {
        return nil
    }
}
