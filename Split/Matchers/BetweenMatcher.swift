//
//  BetweenMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 26/11/2017.
//

import Foundation

class BetweenMatcher: BaseMatcher, MatcherProtocol {

    var data: BetweenMatcherData?

    init(data: BetweenMatcherData?, splitClient: DefaultSplitClient? = nil,
         negate: Bool? = nil, attribute: String? = nil, type: MatcherType? = nil) {
        super.init(splitClient: splitClient, negate: negate, attribute: attribute, type: type)
        self.data = data
    }

    func evaluate(matchValue: Any?, bucketingKey: String?, attributes: [String: Any]?) -> Bool {

        guard let matcherData = data, let dataType = matcherData.dataType, let start = matcherData.start,
            let end = matcherData.end else {
            return false
        }

        switch dataType {

        case DataType.dateTime:
            guard let keyValue = matchValue as? TimeInterval else {return false}
            let backendTimeIntervalStart = TimeInterval(start/1000) //Backend is in millis
            let backendTimeIntervalEnd = TimeInterval(end/1000) //Backend is in millis
            let attributeTimeInterval = keyValue

            let attributeDate = DateTime.zeroOutSeconds(timestamp: attributeTimeInterval)
            let backendDateStart = DateTime.zeroOutSeconds(timestamp: backendTimeIntervalStart)
            let backendDateEnd = DateTime.zeroOutSeconds(timestamp: backendTimeIntervalEnd)

            return attributeDate >= backendDateStart && attributeDate <= backendDateEnd

        case DataType.number:
            guard let keyValue = CastUtils.anyToInt64(value: matchValue) else {return false}
            return keyValue >= start && keyValue <= end
        }
    }
}
