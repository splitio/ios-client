//
//  SplitChangeValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

///
/// A validator for Splits Change
///
protocol SplitChangeValidator {
    ///
    /// Validates a split change instance
    ///
    /// - Parameter change: Split Change to validate
    /// - Returns: nil when validations succeded, otherwise ValidationErrorInfo instance
    ///
    func validate(_ change: SplitChange) -> ValidationErrorInfo?
}

class DefaultSplitChangeValidator: SplitChangeValidator {

    func validate(_ change: SplitChange) -> ValidationErrorInfo? {
        if !(change.splits != nil && change.since != nil && change.till != nil) {
            return ValidationErrorInfo(error: .some, message: "Split change not valid")
        }
        return nil
    }
}
