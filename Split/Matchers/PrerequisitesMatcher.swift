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
        guard let prerequisites = prerequisites, !prerequisites.isEmpty, let evaluator = context?.evaluator else { return true }
        
        for prerequisite in prerequisites {
            guard let splitName = prerequisite.n, let treaments = prerequisite.ts, !treaments.isEmpty else { continue }
            
            do {
                let eval = try evaluator.evalTreatment(matchingKey: values.matchingKey, bucketingKey: values.bucketingKey, splitName: splitName, attributes: nil)
                
                if treaments.contains(values.matchValue as? String ?? "") {
                    return false
                }
            } catch {
                Logger.e("Error evaluating condition in PrerequisitesMatcher: \(error)")
                return false
            }
        }
        
        return true
    }
}
