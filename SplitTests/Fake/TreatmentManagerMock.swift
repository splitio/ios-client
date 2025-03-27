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
    func getTreatment(_ splitName: String, attributes: [String : Any]?, evaluationOptions: EvaluationOptions? = nil) -> String {
        return SplitConstants.control
    }
    
    func getTreatmentWithConfig(_ splitName: String, attributes: [String : Any]?, evaluationOptions: EvaluationOptions? = nil) -> SplitResult {
        return SplitResult(treatment: SplitConstants.control)
    }
    
    func getTreatments(splits: [String], attributes: [String : Any]?, evaluationOptions: EvaluationOptions? = nil) -> [String: String] {
        return dicTreatment(splits: splits)
    }
    
    func getTreatmentsWithConfig(splits: [String], attributes: [String : Any]?, evaluationOptions: EvaluationOptions? = nil) -> [String: SplitResult] {
        return dicResult(splits: splits)
    }
    
    func getTreatmentsByFlagSet(flagSet: String, attributes: [String : Any]?, evaluationOptions: EvaluationOptions? = nil) -> [String: String] {
        return dicTreatment(splits: fSplits)
    }
    
    func getTreatmentsByFlagSets(flagSets: [String], attributes: [String : Any]?, evaluationOptions: EvaluationOptions? = nil) -> [String: String] {
        return dicTreatment(splits: fSplits)
    }
    
    func getTreatmentsWithConfigByFlagSet(flagSet: String, attributes: [String : Any]?, evaluationOptions: EvaluationOptions? = nil) -> [String: SplitResult] {
        return dicResult(splits: fSplits)
    }
    
    func getTreatmentsWithConfigByFlagSets(flagSets: [String], attributes: [String : Any]?, evaluationOptions: EvaluationOptions? = nil) -> [String: SplitResult] {
        return dicResult(splits: fSplits)
    }
    
    func destroy() {
    }

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
