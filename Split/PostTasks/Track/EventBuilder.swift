//
//  EventValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 02/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

enum EventValidationError: Error {
    case nullTrafficType
    case emptyTrafficType
    case emptyMatchingKey
    case nullMatchingKey
    case nullType
    case emptyType
    case invalidType
}

class EventBuilder {
    
    private var matchingKey: String?
    private var type: String?
    private var trafficType: String?
    private var value: Double?
    
    private let kTrackEventNameValidationPattern = "[a-zA-Z0-9][-_.:a-zA-Z0-9]{0,79}"
    
    func setMatchingKey(_ key: String?) -> EventBuilder {
        self.matchingKey = key
        return self
    }
    
    func setType(_ type: String?) -> EventBuilder {
        self.type = type
        return self
    }
    
    func setTrafficType(_ trafficType: String?) -> EventBuilder {
        self.trafficType = trafficType
        return self
    }
    
    func setValue(_ value: Double?) -> EventBuilder {
        self.value = value
        return self
    }
    
    private func validate() throws {
        let tag = "track:"
        if matchingKey == nil {
            Logger.e("\(tag) you passed nil,  key cannot be null")
            throw EventValidationError.nullMatchingKey
        }
        
        if matchingKey!.isEmpty() {
            Logger.e("\(tag) you passed \"\", key must not be an empty string")
            throw EventValidationError.emptyMatchingKey
        }
        
        if trafficType == nil {
            Logger.e("\(tag) you passed nil, traffic_type_name cannot be null")
            throw EventValidationError.nullTrafficType
        }
        
        if trafficType!.isEmpty() {
            Logger.e("\(tag) you passed \"\", traffic_type_name must not be an empty string")
            throw EventValidationError.emptyTrafficType
        }
        
        if type == nil {
            Logger.e("\(tag) you passed nil, event_type cannot be null")
            throw EventValidationError.nullType
        }
        
        if type!.isEmpty() {
            Logger.e("\(tag) you passed \"\", event_type must be not be an empty String")
            throw EventValidationError.emptyType
        }
        
        if !isTypeValid(type!) {
            Logger.e("\(tag) you passed \(type ?? "nil"), event name must adhere to the regular expression \(kTrackEventNameValidationPattern). This means an event name must be alphanumeric, cannot be more than 80 characters long, and can only include a dash, underscore, period, or colon as separators of alphanumeric characters")
            throw EventValidationError.invalidType
        }
    }
    
    private func isTypeValid(_ typeName: String) -> Bool {
        let validationRegex: NSRegularExpression? = try? NSRegularExpression(pattern: kTrackEventNameValidationPattern, options: .caseInsensitive)
        
        if let regex = validationRegex {
            let range = regex.rangeOfFirstMatch(in: typeName, options: [], range: NSRange(location: 0,  length: typeName.count))
            return range.location == 0 && range.length == typeName.count
        }
        return false
    }
    
    func build() throws -> EventDTO  {
        try validate()
        let event: EventDTO = EventDTO(trafficType: trafficType!, eventType: type!)
        event.key = matchingKey
        event.value = value
        event.timestamp = Date().unixTimestampInMiliseconds()
        return event;
    }
}
