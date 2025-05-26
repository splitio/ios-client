//
//  EvaluatorStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10-Nov-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split

class EvaluatorStub: Evaluator {
    var lastAttributes = [Any]()

    func evalTreatment(matchingKey: String, bucketingKey: String?, splitName: String, attributes: [String: Any]?) throws -> EvaluationResult {
        lastAttributes.append(attributes ?? "nil")
        return EvaluationResult(treatment: "on", label: "some")
    }

    func getAttributes(index: Int) -> [String: Any]? {
        let val = lastAttributes[index]
        if let value = val as? String, value == "nil" {
            return nil
        }

        guard let value = val as? [String: Any] else {
            return [String: Any]()
        }
        return value
    }

}
