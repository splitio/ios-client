//
//  EventDTO.swift
//  Split
//
//  Created by Javier Avrudsky on 06/14/2018.
//

import Foundation

class EventDTO: Codable {
    var key: String?
    var eventTypeId: String
    var trafficTypeName: String
    var value: Double?
    var timestamp: Int64?
    
    init(trafficType: String, eventType: String){
        self.trafficTypeName = trafficType
        self.eventTypeId = eventType
    }
    
}
