//
//  EventsHit.swift
//  Split
//
//  Created by Javier L. Avrudsky on 6/19/18.
//

import Foundation

class EventsHit: Codable {
    var identifier: String
    var events: [EventDTO]
    var attempts: Int = 0
    
    init(identifier: String, events: [EventDTO]){
        self.identifier = identifier
        self.events = events
    }
    
    func addAttempt(){
        attempts += 1
    }
    
}
