//
//  ApiKeyValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

///
/// A validator for Key component
///
protocol ApiKeyValidator {
    ///
    /// Validates an Api Key
    ///
    /// - Parameter apiKey: Api key to validate
    /// - Returns: nil when validations succeded, otherwise ValidationErrorInfo instance
    ///
    func validate(apiKey: String?) -> ValidationErrorInfo?
}

class DefaultApiKeyValidator: ApiKeyValidator {

    func validate(apiKey: String?) -> ValidationErrorInfo? {
        if let key = apiKey {
            if key.isEmpty() {
                return ValidationErrorInfo(error: .some,
                                           message: "you passed an empty api_key, api_key must be a non-empty string")
            }
        } else {
            return ValidationErrorInfo(error: .some,
                                       message: "you passed a null api_key, the api_key must be a non-empty string")
        }
        return nil
    }
}
