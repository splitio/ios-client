//  Created by Martin Cardozo on 22/05/2025.
//  Copyright © 2025 Split. All rights reserved.

import Foundation

protocol PrerequisitesMatcherProtocol {
    func evaluate(values: EvalValues, context: EvalContext?) -> Bool
}

class PrerequisitesMatcher: BaseMatcher, MatcherProtocol, PrerequisitesMatcherProtocol {
    
    private var prerequisites: [Prerequisite]?
    
    init(prerequisites: [Prerequisite]? = nil) {
        self.prerequisites = prerequisites
    }

    // This evaluation passes JUST if -all- prerequisite are met
    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {
        guard let prerequisites = prerequisites, !prerequisites.isEmpty else { return true }
        
        for prerequisite in prerequisites {
            guard !prerequisite.treatments.isEmpty else { return true }
            
            do {
                guard let treatment = try context?.evaluator?.evalTreatment(matchingKey: values.matchingKey, bucketingKey: values.bucketingKey, splitName: prerequisite.flagName, attributes: nil).treatment else {
                    continue
                }
                
                if !prerequisite.treatments.contains(treatment) { // ts = Prerequisite treatments list
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
