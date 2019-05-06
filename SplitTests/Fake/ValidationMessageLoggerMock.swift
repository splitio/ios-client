//
//  ValidationMessageLoggerMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 06/05/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

class ValidationMessageLoggerMock: ValidationMessageLogger {
    var messages = [String]()
    func log(errorInfo: ValidationErrorInfo, tag: String) {
        messages.append(errorInfo.errorMessage ?? "")
    }
}
