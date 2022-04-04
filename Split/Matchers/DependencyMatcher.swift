//
//  DependencyMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/14/17.
//

import Foundation

class DependencyMatcher: BaseMatcher, MatcherProtocol {

    var dependencyData: DependencyMatcherData?

    init(negate: Bool? = nil,
         attribute: String? = nil, type: MatcherType? = nil, dependencyData: DependencyMatcherData?) {

        super.init(negate: negate, attribute: attribute, type: type)
        self.dependencyData = dependencyData
    }

    func evaluate(values: EvalValues, context: EvalContext) -> Bool {
        if let splitName = dependencyData?.split {
            let key = Key(matchingKey: values.matchingKey, bucketingKey: values.bucketingKey)
            let treatment = components.treatmentManager.getTreatment(splitName, key: key, attributes: values.attributes)

            if let treatments = dependencyData?.treatments {
                return treatments.contains(treatment)
            } else {
                return false
            }
        }
        return false
    }
}
