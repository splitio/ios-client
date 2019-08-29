//
//  InSegmentMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 24/11/2017.
//

import Foundation

class InSegmentMatcher: BaseMatcher, MatcherProtocol {

    var data: UserDefinedSegmentMatcherData?

    init(data: UserDefinedSegmentMatcherData?, splitClient: InternalSplitClient? = nil,
         negate: Bool? = nil, attribute: String? = nil, type: MatcherType? = nil) {

        super.init(splitClient: splitClient, negate: negate, attribute: attribute, type: type)
        self.data = data
    }

    func evaluate(matchValue: Any?, bucketingKey: String?, attributes: [String: Any]?) -> Bool {

        // Match value is not used because it is matching key. My segments cache only has segments for that key cause
        // Split client is instantiated  based on it
        if matchValue as? String != nil, let dataElements = data, let segmentName = dataElements.segmentName {
            if let segmentFetcher = self.splitClient?.mySegmentsFetcher as? QueryableMySegmentsFetcher {
                return segmentFetcher.isInSegments(name: segmentName)
            }
        }
        return false
    }
}
