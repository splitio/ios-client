//
//  EventValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 21/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

enum EventValidationError: Error {
    case nullTrafficType
    case emptyTrafficType
    case emptyMatchingKey
    case longMatchingKey
    case nullMatchingKey
    case nullType
    case emptyType
    case invalidType
    case unknown
}

enum EventValidationWarning: Error {
    case uppercaseTrafficType
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

    private let tag: String
    
    private let kMaxMatchingKeyLength = ValidationConfig.default.maximumKeyLength
    private let kTrackEventNameValidationPattern = ValidationConfig.default.trackEventNamePattern
    var error: EventValidationError? = nil
    var warnings: [EventValidationWarning] = []
    
    init(tag: String) {
        self.tag = tag
    }
    
    func isValidEntity(_ entity: EventValidatable) -> Bool {
        
        let validatableKey = KeyValidatable(matchingKey: entity.key)
        let keyValidator = KeyValidator(tag: tag)
        
        if !validatableKey.isValid(validator: keyValidator) {
            switch keyValidator.error! {
            case .nullMatchingKey:
                error = EventValidationError.nullMatchingKey
            case .emptyMatchingKey:
                error = EventValidationError.emptyMatchingKey
            case.longMatchingKey:
                error = EventValidationError.longMatchingKey
            default:
                error = EventValidationError.unknown
            }
            return false
        }
        
        if entity.trafficTypeName == nil {
            Logger.e("\(tag): you passed a null or undefined traffic_type_name, traffic_type_name must be a non-empty string")
            error = EventValidationError.nullTrafficType
            return false
        }
        
        if entity.trafficTypeName!.isEmpty() {
            Logger.e("\(tag): you passed an empty traffic_type_name, traffic_type_name must be a non-empty string")
            error = EventValidationError.emptyTrafficType
            return false
        }
        
        if entity.trafficTypeName!.isEmpty() {
            Logger.e("\(tag): you passed an empty traffic_type_name, traffic_type_name must be a non-empty string")
            error = EventValidationError.emptyTrafficType
            return false
        }
        
        if entity.trafficTypeName!.hasUpperCaseChar() {
            Logger.e("\(tag): traffic_type_name should be all lowercase - converting string to lowercase")
            warnings.append(EventValidationWarning.uppercaseTrafficType)
        }
        
        if entity.eventTypeId == nil {
            Logger.e("\(tag): you passed an empty event_type, event_type must be a non-empty String")
            error = EventValidationError.nullType
            return false
        }
        
        if entity.eventTypeId!.isEmpty() {
            Logger.e("\(tag): you passed a null or undefined event_type, event_type must be a non-empty String")
            error = EventValidationError.emptyType
            return false
        }
        
        if !isTypeValid(entity.eventTypeId!) {
            Logger.e("\(tag) you passed \(entity.eventTypeId ?? "null"), event name must adhere to the regular expression \(kTrackEventNameValidationPattern). This means an event name must be alphanumeric, cannot be more than 80 characters long, and can only include a dash, underscore, period, or colon as separators of alphanumeric characters")
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
}
