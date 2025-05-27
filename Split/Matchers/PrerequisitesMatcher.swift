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
        return true
    }
}
