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
    case nullMatchingKey
    case nullType
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
        
        if matchingKey == nil {
            throw EventValidationError.nullMatchingKey
        }
        
        if trafficType == nil {
            throw EventValidationError.nullTrafficType
        }
        
        if type == nil {
            throw EventValidationError.nullType
        }
        
        if !isTypeValid(type!) {
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
