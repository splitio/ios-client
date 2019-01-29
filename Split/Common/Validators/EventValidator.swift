//
//  EventValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 21/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

struct EventValidationError {
    static let nullTrafficType: Int = 1
    static let emptyTrafficType: Int = 2
    static let emptyMatchingKey: Int = 3
    static let longMatchingKey: Int = 4
    static let nullMatchingKey: Int = 5
    static let nullType: Int = 6
    static let emptyType: Int = 7
    static let invalidType: Int = 8
    static let unknown: Int = 9
}

struct EventValidationWarning {
    static let uppercaseTrafficType: Int = 101
}

struct EventValidatable: Validatable {
    
    typealias Entity = EventValidatable
    
    var key: String?
    var eventTypeId: String?
    var trafficTypeName: String?
    var value: Double?
    
    func isValid<V>(validator: V) -> Bool where V : Validator, V.Entity == Entity {
        return validator.isValidEntity(self)
    }
}

class EventValidator: Validator {
    
    private let kMaxMatchingKeyLength = ValidationConfig.default.maximumKeyLength
    private let kTrackEventNameValidationPattern = ValidationConfig.default.trackEventNamePattern
    var error: Int? = nil
    var warnings: [Int] = []
    var messageLogger: ValidationMessageLogger
    let tag: String
    
    init(tag: String) {
        self.messageLogger = DefaultValidationMessageLogger(tag: tag)
        self.tag = tag
    }
    
    func isValidEntity(_ entity: EventValidatable) -> Bool {
        warnings.removeAll()
        let validatableKey = KeyValidatable(matchingKey: entity.key)
        let keyValidator = KeyValidator(tag: tag)
        
        if !validatableKey.isValid(validator: keyValidator) {
            error = mapKeyErrorToEventError(keyError: keyValidator.error!)
            return false
        }
        
        if entity.trafficTypeName == nil {
            messageLogger.e("you passed a null or undefined traffic_type_name, traffic_type_name must be a non-empty string")
            error = EventValidationError.nullTrafficType
            return false
        }
        
        if entity.trafficTypeName!.isEmpty() {
            messageLogger.e("you passed an empty traffic_type_name, traffic_type_name must be a non-empty string")
            error = EventValidationError.emptyTrafficType
            return false
        }
        
        if entity.trafficTypeName!.hasUpperCaseChar() {
            messageLogger.e("traffic_type_name should be all lowercase - converting string to lowercase")
            warnings.append(EventValidationWarning.uppercaseTrafficType)
        }
        
        if entity.eventTypeId == nil {
            messageLogger.e("you passed a null or undefined event_type, event_type must be a non-empty String")
            error = EventValidationError.nullType
            return false
        }
        
        if entity.eventTypeId!.isEmpty() {
            messageLogger.e("you passed an empty event_type, event_type must be a non-empty String")
            error = EventValidationError.emptyType
            return false
        }
        
        if !isTypeValid(entity.eventTypeId!) {
            messageLogger.e("\(tag) you passed \(entity.eventTypeId ?? "null"), event name must adhere to the regular expression \(kTrackEventNameValidationPattern). This means an event name must be alphanumeric, cannot be more than 80 characters long, and can only include a dash, underscore, period, or colon as separators of alphanumeric characters")
            error = EventValidationError.invalidType
            return false
        }
        error = nil
        return true
    }

    private func isTypeValid(_ typeName: String) -> Bool {
        let validationRegex: NSRegularExpression? = try? NSRegularExpression(pattern: kTrackEventNameValidationPattern, options: .caseInsensitive)
        if let regex = validationRegex {
            let range = regex.rangeOfFirstMatch(in: typeName, options: [], range: NSRange(location: 0,  length: typeName.count))
            return range.location == 0 && range.length == typeName.count
        }
        return false
    }
    
    private func mapKeyErrorToEventError(keyError: Int) -> Int {
        var error: Int!
        switch keyError {
        case KeyValidationError.nullMatchingKey:
            error = EventValidationError.nullMatchingKey
        case KeyValidationError.emptyMatchingKey:
            error = EventValidationError.emptyMatchingKey
        case KeyValidationError.longMatchingKey:
            error = EventValidationError.longMatchingKey
        default:
            error = EventValidationError.unknown
        }
        return error
    }
}
