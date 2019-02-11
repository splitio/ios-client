//
//  EventValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 21/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

/**
 A validator for Track events
 */
protocol EventValidator {
    func validate(key: String?, trafficTypeName: String?, eventTypeId: String?, value: Double?) -> ValidationErrorInfo?
}

class DefaultEventValidator: EventValidator {
    
    private let kMaxMatchingKeyLength = ValidationConfig.default.maximumKeyLength
    private let kTrackEventNameValidationPattern = ValidationConfig.default.trackEventNamePattern
    
    var keyValidator: KeyValidator
    
    init(){
        keyValidator = DefaultKeyValidator()
    }
    
    func validate(key: String?, trafficTypeName: String?, eventTypeId: String?, value: Double?) -> ValidationErrorInfo? {
        
        if let resultInfo = keyValidator.validate(matchingKey: key, bucketingKey: nil) {
            return resultInfo
        }
        
        if trafficTypeName == nil {
            return ValidationErrorInfo(error: .some, message: "you passed a null or undefined traffic_type_name, traffic_type_name must be a non-empty string")
        }
        
        if trafficTypeName!.isEmpty() {
            return ValidationErrorInfo(error: .some, message: "you passed an empty traffic_type_name, traffic_type_name must be a non-empty string")
        }

        if eventTypeId == nil {
            return ValidationErrorInfo(error: .some, message: "you passed a null or undefined event_type, event_type must be a non-empty String")
        }
        
        if eventTypeId!.isEmpty() {
            return ValidationErrorInfo(error: .some, message: "you passed an empty event_type, event_type must be a non-empty String")
        }
        
        if !isTypeValid(eventTypeId!) {
            return ValidationErrorInfo(error: .some, message: "you passed \(eventTypeId ?? "null"), event name must adhere to the regular expression \(kTrackEventNameValidationPattern). This means an event name must be alphanumeric, cannot be more than 80 characters long, and can only include a dash, underscore, period, or colon as separators of alphanumeric characters")
        }
        
        if trafficTypeName!.hasUpperCaseChar() {
            return ValidationErrorInfo(warning: .trafficTypeNameHasUppercaseChars , message: "traffic_type_name should be all lowercase - converting string to lowercase")
        }
        return nil
    }

    private func isTypeValid(_ typeName: String) -> Bool {
        let validationRegex: NSRegularExpression? = try? NSRegularExpression(pattern: kTrackEventNameValidationPattern, options: .caseInsensitive)
        if let regex = validationRegex {
            let range = regex.rangeOfFirstMatch(in: typeName, options: [], range: NSRange(location: 0,  length: typeName.count))
            return range.location == 0 && range.length == typeName.count
        }
        return false
    }
}
