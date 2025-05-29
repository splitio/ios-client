//
//  InSegmentMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 24/11/2017.
//

import Foundation

class BaseInSegmentMatcher: BaseMatcher, MatcherProtocol {
    var data: UserDefinedBaseSegmentMatcherData?

    init(
        data: UserDefinedBaseSegmentMatcherData?,
        negate: Bool? = nil,
        attribute: String? = nil,
        type: MatcherType? = nil) {
        super.init(negate: negate, attribute: attribute, type: type)
        self.data = data
    }

    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {
        // Using wrappers because Segments and Large segments use the same data and logic to evaluate
        // but properties from BE are different.
        let storage = storageFromContext(context)
        let name = nameFromContext(context, data)
        // Match value is not used because it is matching key. My segments cache only has segments for that key cause
        // Split client is instantiated  based on it
        if values.matchValue is String, let segmentName = name {
            return storage?.getAll(forKey: values.matchingKey).contains(segmentName) ?? false
        }
        return false
    }

    func storageFromContext(_ context: EvalContext?) -> MySegmentsStorage? {
        fatalError("function not implemented \(#function)")
    }

    func nameFromContext(_ context: EvalContext?, _ data: UserDefinedBaseSegmentMatcherData?) -> String? {
        fatalError("function not implemented \(#function)")
    }
}

class InSegmentMatcher: BaseInSegmentMatcher {
    override func storageFromContext(_ context: EvalContext?) -> MySegmentsStorage? {
        return context?.mySegmentsStorage
    }

    override func nameFromContext(_ context: EvalContext?, _ data: UserDefinedBaseSegmentMatcherData?) -> String? {
        return data?.segmentName
    }
}

class InLargeSegmentMatcher: BaseInSegmentMatcher {
    override func storageFromContext(_ context: EvalContext?) -> MySegmentsStorage? {
        return context?.myLargeSegmentsStorage
    }

    override func nameFromContext(_ context: EvalContext?, _ data: UserDefinedBaseSegmentMatcherData?) -> String? {
        return data?.largeSegmentName
    }
}
