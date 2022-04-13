//
//  InSegmentMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 24/11/2017.
//

import Foundation

class InSegmentMatcher: BaseMatcher, MatcherProtocol {

    var data: UserDefinedSegmentMatcherData?

    init(data: UserDefinedSegmentMatcherData?,
         negate: Bool? = nil, attribute: String? = nil, type: MatcherType? = nil) {

        super.init(negate: negate, attribute: attribute, type: type)
        self.data = data
    }

    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {

        // Match value is not used because it is matching key. My segments cache only has segments for that key cause
        // Split client is instantiated  based on it
        if values.matchValue as? String != nil, let dataElements = data, let segmentName = dataElements.segmentName {
            return context?.mySegmentsStorage?.getAll(forKey: values.matchingKey).contains(segmentName) ?? false
        }
        return false
    }
}
