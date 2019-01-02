//
//  EventFactory.swift
//  Split
//
//  Created by Javier L. Avrudsky on 02/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

class EventFactory {
    
    
    public func create(type: String, trafficType: String? = nil, value: Double? = nil) -> EventDTO? {
        
        var finalTrafficType: String? = nil
        if let trafficType = trafficType {
            finalTrafficType = trafficType
        } else if let trafficType = self.config?.trafficType {
            finalTrafficType = trafficType
        } else {
            return false
        }
        
        let event: EventDTO = EventDTO(trafficType: finalTrafficType!, eventType: eventType)
        event.key = self.key.matchingKey
        event.value = value
        event.timestamp = Date().unixTimestampInMiliseconds()
        trackEventsManager.appendEvent(event: event)
        
        return true
    }
    
    private func validateEventName(eventName: String) -> Bool {
        let validationRegex: NSRegularExpression? = try? NSRegularExpression(pattern: kTrackEventNameValidationPattern, options: .caseInsensitive)
        
        if let regex = validationRegex {
            let matchesCount = regex.numberOfMatches(in: eventName, options: [], range: NSRange(location: 0,  length: eventName.count))
            if matchesCount == 1 {
                return true
            }
        }
        return false
    }
    
    
}
