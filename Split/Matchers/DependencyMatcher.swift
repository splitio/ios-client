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

    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {

        if let splitName = dependencyData?.split {
            var treatment = SplitConstants.control
            do {
                treatment = try context?.evaluator?.evalTreatment(
                    matchingKey: values.matchingKey,
                    bucketingKey: values.bucketingKey,
                    splitName: splitName,
                    attributes: values.attributes).treatment ?? SplitConstants.control

            } catch {
                return false
            }

            if let treatments = dependencyData?.treatments {
                return treatments.contains(treatment)
            } else {
                return false
            }
        }
        return false
    }
}
