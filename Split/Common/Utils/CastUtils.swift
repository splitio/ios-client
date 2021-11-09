//
//  CastUtils.swift
//  Split
//
//  Created by Javier L. Avrudsky on 16/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//
// This class was created as a workaround to fix some convertion problems
// related to Int datatypes until doing a full refactor.
// ToDo: Refactor Int usages

import Foundation

class CastUtils {
    static func anyToInt64(value: Any?) -> Int64? {
        if let val = value as? NSNumber {
            if val.intValue <= Int64.max {
                return Int64(truncating: val)
            }
        }
        return nil
    }

    static func fixDoublePrecisionIssue(values: [String: Any]) -> [String: Any] {
        var parsedValues = [String: Any]()
        for (key, value) in values {
            // Workaround to avoid lost of precision of Decimal(double:) constructor
            if !(value is Bool || value is String), let doubleValue = value as? Double {
                parsedValues[key] = Decimal(string: String(doubleValue))
            } else {
                parsedValues[key] = value
            }
        }
        return parsedValues
    }
}
