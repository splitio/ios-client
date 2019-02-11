//
//  ValidatorMessageLogger.swift
//  Split
//
//  Created by Javier L. Avrudsky on 29/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

/**
  Protocol to implement to create a
  logger for validations components
 */
protocol ValidationMessageLogger {
    func log(errorInfo: ValidationErrorInfo, tag: String)
}

/**
  Default implementation of ValidationMessageLogger protocol
 */
class DefaultValidationMessageLogger: ValidationMessageLogger {
    
    func log(errorInfo: ValidationErrorInfo, tag: String) {
        if errorInfo.isError, let message = errorInfo.errorMessage {
            e(message: message, tag: tag)
        } else {
            let warnings = errorInfo.warnings.values
            for warning in warnings {
                w(message: warning, tag: tag)
            }
        }
    }

    private func e(message: String, tag: String = "") {
        Logger.e("\(tag): \(message)")
    }
    
    private func w(message: String, tag: String = "") {
        Logger.w("\(tag): \(message)")
    }
}
