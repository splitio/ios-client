//
//  KeyValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

protocol KeyValidator {
    ///
    /// Validates matching and bucketing keys
    ///
    /// - Parameters:
    ///     - matchingKey: Matching key to validate
    ///     - bucketingKey: Bucketing key to validate
    /// - Returns: nil when validations succeded, otherwise ValidationErrorInfo instance
    ///
    func validate(matchingKey: String?, bucketingKey: String?) -> ValidationErrorInfo?
}

///
/// Default implementation of key validator
///
class DefaultKeyValidator: KeyValidator {

    let kMaxMatchingKeyLength = ValidationConfig.default.maximumKeyLength
    let kMaxBucketingKeyLength = ValidationConfig.default.maximumKeyLength

    func validate(matchingKey: String?, bucketingKey: String?) -> ValidationErrorInfo? {
        if let key = matchingKey {
            if key.isEmpty() {
                return ValidationErrorInfo(error: .some,
                                           message: "you passed an empty string, matching key must a non-empty string")
            }

            if key.count > kMaxMatchingKeyLength {
                return ValidationErrorInfo(error: .some,
                                           message: "matching key too long - must be \(kMaxMatchingKeyLength) " +
                    "characters or less")
            }
        } else {
            return ValidationErrorInfo(error: .some,
                                       message: "you passed a null key, the key must be a non-empty string")
        }

        if let key = bucketingKey {
            if key.isEmpty() {
                return ValidationErrorInfo(error: .some,
                                           message: "you passed an empty string, bucketing " +
                    "key must be null or a non-empty string")
            }

            if key.count > kMaxBucketingKeyLength {
                return ValidationErrorInfo(error: .some,
                                           message: "bucketing key too long - must be \(kMaxBucketingKeyLength) " +
                    "characters or less")
            }
        }
        return nil
    }
}
