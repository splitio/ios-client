//
//  FlagSetValidator.swift
//  Split
//
//  Created by Javier Avrudsky on 22/09/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

protocol FlagSetsValidator {
    func validateOnEvaluation(_ values: [String], calledFrom method: String, setsInFilter: [String]) -> [String]
    func cleanAndValidateValues(_ values: [String], calledFrom method: String) -> [String]
}

struct DefaultFlagSetsValidator: FlagSetsValidator {
    private var telemetryProducer: TelemetryInitProducer?

    init(telemetryProducer: TelemetryInitProducer?) {
        self.telemetryProducer = telemetryProducer
    }

    private let setRegex = "^[a-z0-9][a-z0-9_]{0,49}$"

    func validateOnEvaluation(_ values: [String], calledFrom method: String, setsInFilter: [String]) -> [String] {
        let filterSet = Set(setsInFilter)
        return cleanAndValidateValues(values, calledFrom: method).filter { value in
            if !filterSet.isEmpty, !filterSet.contains(value) {
                Logger.w(
                    "\(method): you passed Flag Set: \(value) and is not part of " +
                        "the configured Flag set list, ignoring the request.")
                return false
            }
            return true
        }
    }

    func cleanAndValidateValues(_ values: [String], calledFrom method: String = "SDK Init") -> [String] {
        var cleanSets = Set<String>()
        for value in values {
            let cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if cleanValue.count < value.count {
                Logger.w("\(method): Flag Set name <<\(value)>> has extra whitespace, trimming")
            }
            if !isValid(cleanValue) {
                Logger.w(
                    "\(method): you passed \(cleanValue), Flag Set must adhere to the regular " +
                        "expressions \(setRegex). This means an Flag Set must be start with a letter, " +
                        "be in lowercase, alphanumeric and have a max length of 50 characters." +
                        "\(cleanValue) was discarded.")
                continue
            }
            if !cleanSets.insert(cleanValue).inserted {
                Logger.w("\(method): you passed duplicated Flag Set. \(cleanValue) was deduplicated.")
            }
        }
        telemetryProducer?.recordTotalFlagSets(values.count)
        telemetryProducer?.recordInvalidFlagSets(values.count - cleanSets.count)
        return Array(cleanSets)
    }

    private func isValid(_ value: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: setRegex)
        let range = NSRange(location: 0, length: value.utf16.count)
        return regex?.numberOfMatches(in: value, options: [], range: range) ?? 0 > 0
    }
}
