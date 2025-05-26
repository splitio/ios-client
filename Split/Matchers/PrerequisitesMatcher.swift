//  Created by Martin Cardozo on 22/05/2025.
//  Copyright © 2025 Split. All rights reserved.

import Foundation

class PrerequisitesMatcher: BaseMatcher, MatcherProtocol {

    private var prerequisites: [Prerequisite]?
    
    init(prerequisites: [Prerequisite]? = nil) {
        self.prerequisites = prerequisites
    }

    // This evaluation passes JUST if -all- prerequisite are met
    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {
        
        guard let prerequisites = prerequisites, !prerequisites.isEmpty else { return true }
        
        for prerequisite in prerequisites {
            guard !prerequisite.ts.isEmpty else { return true }
            
            do {
                let evalResult = try context?.evaluator?.evalTreatment(matchingKey: values.matchingKey, bucketingKey: values.bucketingKey, splitName: prerequisite.n, attributes: nil)
                
                if let treatment = evalResult?.treatment {
                    if !prerequisite.ts.contains(treatment) {
                        return false
                    }
                }
            } catch {
                Logger.e("Error evaluating condition in PrerequisitesMatcher: \(error)")
                return false
            }
        }
        
        return true
    }
}
