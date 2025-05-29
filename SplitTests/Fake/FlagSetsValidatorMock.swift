//
//  FlagSetsValidationMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 02/10/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
@testable import Split

class FlagSetsValidatorMock: FlagSetsValidator {
    var validateOnEvaluatioResults = [String]()
    func validateOnEvaluation(_ values: [String], calledFrom method: String, setsInFilter: [String]) -> [String] {
        let set1 = Set(validateOnEvaluatioResults)
        let set2 = Set(values)

        return Array(set1.intersection(set2))
    }

    var cleanAndValidateValuesResult = [String]()
    func cleanAndValidateValues(_ values: [String], calledFrom method: String) -> [String] {
        let set1 = Set(validateOnEvaluatioResults)
        let set2 = Set(values)

        return Array(set1.intersection(set2))
    }
}
