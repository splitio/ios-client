//
//  LessThanOrEqualToMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 24/11/2017.
//

import Foundation

class LessThanOrEqualToMatcher: BaseMatcher, MatcherProtocol {

    var data: UnaryNumericMatcherData?

    init(data: UnaryNumericMatcherData?,
         negate: Bool? = nil,
         attribute: String? = nil,
         type: MatcherType? = nil) {

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
            let backendTimeInterval = TimeInterval(value/1000) // Backend is in millis
            let attributeTimeInterval = keyValue
            let attributeDate = DateTime.zeroOutSeconds(timestamp: attributeTimeInterval)
            let backendDate = DateTime.zeroOutSeconds(timestamp: backendTimeInterval)
            return  attributeDate <= backendDate
        case DataType.number:
            guard let keyValue = CastUtils.anyToInt64(value: values.matchValue) else {return false}
            return keyValue <= value
        }
    }
}
