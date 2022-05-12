//
//  DependencyMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/14/17.
//

import Foundation

class DependencyMatcher: BaseMatcher, MatcherProtocol {

    var dependencyData: DependencyMatcherData?

    init(splitClient: InternalSplitClient? = nil, negate: Bool? = nil,
         attribute: String? = nil, type: MatcherType? = nil, dependencyData: DependencyMatcherData?) {

        super.init(splitClient: splitClient, negate: negate, attribute: attribute, type: type)
        self.dependencyData = dependencyData
    }

    func evaluate(matchValue: Any?, bucketingKey: String?, attributes: [String: Any]?) -> Bool {

        if let splitName = dependencyData?.split {

            var treatment: String?
            treatment = splitClient?.getTreatment(splitName, attributes: attributes)

            if let treatments = dependencyData?.treatments {
                return treatments.contains(treatment!)
            } else {
                return false
            }
        }
        return false
    }
}
