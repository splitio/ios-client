//
//  EventsFile.swift
//  Split
//
//  Created by Javier L. Avrudsky on 6/19/18.
//

import Foundation

class EventsFile: Codable {
    var oldHits: [String: EventsHit]?
    var currentHit: EventsHit?
}
