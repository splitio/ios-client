//
//  ValidatorMessageLogger.swift
//  Split
//
//  Created by Javier L. Avrudsky on 29/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

///
/// Tags to use when logging message on validation
///
struct ValidationTag {
    static let getTreatmentWithConfig = "getTreatmentWithConfig"
    static let getTreatmentsWithConfig = "getTreatmentsWithConfig"
    static let getTreatment = "getTreatment"
    static let getTreatments = "getTreatments"
}

///
/// Protocol to implement to create a
/// logger for validations components
/// The component will be responsible to log information
/// about validation failures or warnings
///
protocol ValidationMessageLogger {
    ///
    /// Logs info related a validation fail or warning
    /// - Parameters:
    ///     - errorInfo: Info about a failed validation result
    ///     - tag: Tag for a log line
    ///
    func log(errorInfo: ValidationErrorInfo, tag: String)

    ///
    /// Logs error level info
    /// - Parameters:
    ///     - message: Error message to log in console
    ///     - tag: Tag for a log line
    ///
    func e(message: String, tag: String)

    ///
    /// Logs warning level info
    /// - Parameters:
    ///     - message: Warning message to log in console
    ///     - tag: Tag for a log line
    ///
    func w(message: String, tag: String)
}

///
///  Default implementation of ValidationMessageLogger protocol
///
class DefaultValidationMessageLogger: ValidationMessageLogger {

    func log(errorInfo: ValidationErrorInfo, tag: String) {
        if errorInfo.isError, let message = errorInfo.errorMessage {
            logError(message: message, tag: tag)
        } else {
            let warnings = errorInfo.warnings.values
            for warning in warnings {
                logWarning(message: warning, tag: tag)
            }
        }
    }

    func e(message: String, tag: String = "") {
        logWarning(message: message, tag: tag)
    }

    func w(message: String, tag: String = "") {
        logWarning(message: message, tag: tag)
    }

    private func logError(message: String, tag: String = "") {
        Logger.e("\(tag): \(message)")
    }

    private func logWarning(message: String, tag: String = "") {
        Logger.w("\(tag): \(message)")
    }
}
