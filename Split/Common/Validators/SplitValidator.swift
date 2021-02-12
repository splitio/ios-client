//
//  SplitNameValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

///
/// A validator for Splits name
///

protocol SplitValidator {
    ///
    /// Validates a split name
    ///
    /// - Parameter name: Split name to validate
    /// - Returns: nil when validations succeded, otherwise ValidationErrorInfo instance
    ///
    func validate(name: String?) -> ValidationErrorInfo?

    ///
    /// Validates a split
    ///
    /// - Parameter name: Name of the split to validate
    /// - Returns: nil when validations succeded, otherwise ValidationErrorInfo instance
    ///
    func validateSplit(name: String) -> ValidationErrorInfo?
}

struct SplitNameValidator {
    func validate(name: String?) -> ValidationErrorInfo? {

        if name == nil {
            return ValidationErrorInfo(error: .some,
                                       message: "you passed a null split name, split name must be a non-empty string")
        }

        if name!.isEmpty() {
            return ValidationErrorInfo(error: .some,
                                       message: "you passed an empty split name, split name must be a non-empty string")
        }

        if name!.trimmingCharacters(in: .whitespacesAndNewlines) != name! {
            return ValidationErrorInfo(warning: .splitNameShouldBeTrimmed,
                                       message: "split name '\(name!)' has extra whitespace, trimming")
        }

        return nil
    }
}

class DefaultSplitValidator: SplitValidator {

    let splitsStorage: SplitsStorage
    let splitNameValidator = SplitNameValidator()

    init(splitsStorage: SplitsStorage) {
        self.splitsStorage = splitsStorage
    }

    func validate(name: String?) -> ValidationErrorInfo? {
        return splitNameValidator.validate(name: name)
    }

    func validateSplit(name: String) -> ValidationErrorInfo? {
        if splitsStorage.get(name: name) == nil {
            return ValidationErrorInfo(warning: .nonExistingSplit,
                                       message: "you passed '\(name)' that does not exist in this environment, " +
                "please double check what Splits exist in the web console.")
        }
        return nil
    }
}
