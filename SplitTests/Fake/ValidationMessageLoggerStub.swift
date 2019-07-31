//
//  ValidationMessageLoggerStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 06/05/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

struct WarningMessageItemStub {
    var tag: String
    var message: String
}

class ValidationMessageLoggerStub: ValidationMessageLogger {
    
    var errorTag: String?
    var errorMessage: String?
    
    var hasError: Bool {
        return (errorMessage != nil)
    }
    
    var hasWarnings: Bool {
        return (warnings.count > 0)
    }
    
    var warnings: [WarningMessageItemStub]
    
    init() {
        errorTag = nil
        errorMessage = nil
        warnings = [WarningMessageItemStub]()
    }
    
    func e(message: String, tag: String) {
        errorTag = tag
        errorMessage = message
    }
    
    func w(message: String, tag: String) {
        warnings.append(WarningMessageItemStub(tag: tag, message: message))
    }
    
    var messages = [String]()
    func log(errorInfo: ValidationErrorInfo, tag: String) {
        messages.append(errorInfo.errorMessage ?? "")
        if(errorInfo.isError) {
            errorMessage = errorInfo.errorMessage
            errorTag = tag
        } else {
            for warning in errorInfo.warnings {
                warnings.append(WarningMessageItemStub(tag: tag, message: warning.value))
            }
        }
    }
}
