//
//  EventsHit.swift
//  Split
//
//  Created by Javier L. Avrudsky on 6/19/18.
//

import Foundation

class EventsHit: DynamicCodable {

    var identifier: String
    var events: [EventDTO]
    var attempts: Int = 0

    init(identifier: String, events: [EventDTO]) {
        self.identifier = identifier
        self.events = events
    }

    func addAttempt() {
        attempts += 1
    }

    required init(jsonObject: Any) throws {
        guard let data = jsonObject as? [String: Any] else {
            throw SplitEncodingError.unknown
        }

        identifier = data["identifier"] as? String ?? ""
        attempts = data["attempts"] as? Int ?? 0

        guard let eventsData = data["events"] else {
            throw SplitEncodingError.unknown
        }
        events = try [EventDTO](jsonObject: eventsData)
    }

    func toJsonObject() -> Any {
        var jsonObject = [String: Any]()
        jsonObject["identifier"] = identifier
        jsonObject["attempts"] = attempts
        jsonObject["events"] = events.toJsonObject()
        return jsonObject
    }
}
