//
//  EqualToMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/23/17.
//

import Foundation

class EqualToMatcher: BaseMatcher, MatcherProtocol {

    var data: UnaryNumericMatcherData?

    init(data: UnaryNumericMatcherData?, splitClient: DefaultSplitClient? = nil,
         negate: Bool? = nil, attribute: String? = nil, type: MatcherType? = nil) {

        super.init(negate: negate, attribute: attribute, type: type)
        self.data = data
    }

    func evaluate(values: EvalValues, context: EvalContext?) -> Bool {

        guard let matcherData = data, let dataType = matcherData.dataType, let value = matcherData.value else {
            return false
        }

        switch dataType {
        case DataType.dateTime:
            guard let keyValue = values.matchValue as? TimeInterval else {return false}
            let backendTimeInterval = TimeInterval(value/1000)
            let attributeTimeInterval = keyValue

            let attributeDate = DateTime.zeroOutTime(timestamp: attributeTimeInterval)
            let backendDate = DateTime.zeroOutTime(timestamp: backendTimeInterval)
            return backendDate == attributeDate

        case DataType.number:
            guard let keyValue = CastUtils.anyToInt64(value: values.matchValue) else {return false}
            return keyValue == value
        }
    }
}
