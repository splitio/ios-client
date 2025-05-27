//  Created by Martin Cardozo on 27/05/2025.
//  Copyright © 2025 Split. All rights reserved.

@testable import Split

class PrerequisitesMatcherMock: BaseMatcher, MatcherProtocol, PrerequisitesMatcherProtocol {

    private let returnValue: Bool

    init(shouldPass: Bool) {
        self.returnValue = shouldPass
    }

    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {
        returnValue
    }
}
