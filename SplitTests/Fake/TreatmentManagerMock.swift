//
//  TreatmentManagerMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10/04/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split

class TreatmentManagerMock: TreatmentManager {
    let fSplits = ["split1", "split2"]

    // Track method calls with evaluationOptions
    var getTreatmentCalled = false
    var getTreatmentWithConfigCalled = false
    var getTreatmentsCalled = false
    var getTreatmentsWithConfigCalled = false
    var getTreatmentsByFlagSetCalled = false
    var getTreatmentsByFlagSetsCalled = false
    var getTreatmentsWithConfigByFlagSetCalled = false
    var getTreatmentsWithConfigByFlagSetsCalled = false

    // Store the last evaluationOptions passed to each method
    var lastGetTreatmentEvaluationOptions: EvaluationOptions?
    var lastGetTreatmentWithConfigEvaluationOptions: EvaluationOptions?
    var lastGetTreatmentsEvaluationOptions: EvaluationOptions?
    var lastGetTreatmentsWithConfigEvaluationOptions: EvaluationOptions?
    var lastGetTreatmentsByFlagSetEvaluationOptions: EvaluationOptions?
    var lastGetTreatmentsByFlagSetsEvaluationOptions: EvaluationOptions?
    var lastGetTreatmentsWithConfigByFlagSetEvaluationOptions: EvaluationOptions?
    var lastGetTreatmentsWithConfigByFlagSetsEvaluationOptions: EvaluationOptions?

    func getTreatment(
        _ splitName: String,
        attributes: [String: Any]?,
        evaluationOptions: EvaluationOptions? = nil) -> String {
        getTreatmentCalled = true
        lastGetTreatmentEvaluationOptions = evaluationOptions
        return SplitConstants.control
    }

    func getTreatmentWithConfig(
        _ splitName: String,
        attributes: [String: Any]?,
        evaluationOptions: EvaluationOptions? = nil) -> SplitResult {
        getTreatmentWithConfigCalled = true
        lastGetTreatmentWithConfigEvaluationOptions = evaluationOptions
        return SplitResult(treatment: SplitConstants.control)
    }

    func getTreatments(
        splits: [String],
        attributes: [String: Any]?,
        evaluationOptions: EvaluationOptions? = nil) -> [String: String] {
        getTreatmentsCalled = true
        lastGetTreatmentsEvaluationOptions = evaluationOptions
        return dicTreatment(splits: splits)
    }

    func getTreatmentsWithConfig(
        splits: [String],
        attributes: [String: Any]?,
        evaluationOptions: EvaluationOptions? = nil) -> [String: SplitResult] {
        getTreatmentsWithConfigCalled = true
        lastGetTreatmentsWithConfigEvaluationOptions = evaluationOptions
        return dicResult(splits: splits)
    }

    func getTreatmentsByFlagSet(
        flagSet: String,
        attributes: [String: Any]?,
        evaluationOptions: EvaluationOptions? = nil) -> [String: String] {
        getTreatmentsByFlagSetCalled = true
        lastGetTreatmentsByFlagSetEvaluationOptions = evaluationOptions
        return dicTreatment(splits: fSplits)
    }

    func getTreatmentsByFlagSets(
        flagSets: [String],
        attributes: [String: Any]?,
        evaluationOptions: EvaluationOptions? = nil) -> [String: String] {
        getTreatmentsByFlagSetsCalled = true
        lastGetTreatmentsByFlagSetsEvaluationOptions = evaluationOptions
        return dicTreatment(splits: fSplits)
    }

    func getTreatmentsWithConfigByFlagSet(
        flagSet: String,
        attributes: [String: Any]?,
        evaluationOptions: EvaluationOptions? = nil) -> [String: SplitResult] {
        getTreatmentsWithConfigByFlagSetCalled = true
        lastGetTreatmentsWithConfigByFlagSetEvaluationOptions = evaluationOptions
        return dicResult(splits: fSplits)
    }

    func getTreatmentsWithConfigByFlagSets(
        flagSets: [String],
        attributes: [String: Any]?,
        evaluationOptions: EvaluationOptions? = nil) -> [String: SplitResult] {
        getTreatmentsWithConfigByFlagSetsCalled = true
        lastGetTreatmentsWithConfigByFlagSetsEvaluationOptions = evaluationOptions
        return dicResult(splits: fSplits)
    }

    func destroy() {}

    private func dicTreatment(splits: [String]) -> [String: String] {
        var result = [String: String]()
        for split in splits {
            result[split] = SplitConstants.control
        }
        return result
    }

    private func dicResult(splits: [String]) -> [String: SplitResult] {
        var result = [String: SplitResult]()
        for split in splits {
            result[split] = SplitResult(treatment: SplitConstants.control)
        }
        return result
    }
}
