//
//  TreatmentManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 22-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol TreatmentManager: Destroyable {
    // MARK: Basic evaluation

    func getTreatment(_ splitName: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> String
    func getTreatmentWithConfig(_ splitName: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?)
        -> SplitResult
    func getTreatments(splits: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?)
        -> [String: String]
    func getTreatmentsWithConfig(splits: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?)
        -> [String: SplitResult]

    // MARK: Evaluation with flagsets

    func getTreatmentsByFlagSet(flagSet: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?)
        -> [String: String]
    func getTreatmentsByFlagSets(flagSets: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?)
        -> [String: String]
    func getTreatmentsWithConfigByFlagSet(
        flagSet: String,
        attributes: [String: Any]?,
        evaluationOptions: EvaluationOptions?) -> [String: SplitResult]
    func getTreatmentsWithConfigByFlagSets(
        flagSets: [String],
        attributes: [String: Any]?,
        evaluationOptions: EvaluationOptions?) -> [String: SplitResult]
}
