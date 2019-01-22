//
//  EventValidator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 02/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

class EventBuilder {
    
    private var key: String?
    private var type: String?
    private var trafficType: String?
    private var value: Double?
    
    
    
    func setKey(_ key: String?) -> EventBuilder {
        self.key = key
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
        var eventValidatable = EventValidatable()
        eventValidatable.key = self.key
        eventValidatable.value = self.value
        eventValidatable.trafficTypeName = self.trafficType
        eventValidatable.key = self.key
        
        let eventValidator = EventValidator(tag: "track")
        if !eventValidatable.isValid(validator: eventValidator) {
            throw eventValidator.error!
        }
        
        if eventValidator.warnings.count > 0, eventValidator.warnings[0] == EventValidationWarning.uppercaseTrafficType {
            self.trafficType = self.trafficType!.lowercased()
        }
    }
    
    func build() throws -> EventDTO  {
        try validate()
        let event: EventDTO = EventDTO(trafficType: trafficType!, eventType: type!)
        event.key = key
        event.value = value
        event.timestamp = Date().unixTimestampInMiliseconds()
        return event;
    }
}
