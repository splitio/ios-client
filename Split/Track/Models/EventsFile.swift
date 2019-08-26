//
//  EventsFile.swift
//  Split
//
//  Created by Javier L. Avrudsky on 6/19/18.
//

import Foundation

class EventsFile: DynamicCodable {

    var oldHits: [String: EventsHit]?
    var currentHit: EventsHit?

    init() {
    }

    required init(jsonObject: Any) throws {
        if let jsonObj = jsonObject as? [String: Any] {
            if let jsonOldHits = jsonObj["oldHits"] {
                oldHits = try [String: EventsHit](jsonObject: jsonOldHits)
            }

            if let jsonCurrentHit = jsonObj["currentHit"] {
                currentHit = try? EventsHit(jsonObject: jsonCurrentHit)
            }
        }
    }

    func toJsonObject() -> Any {
        var jsonObject = [String: Any]()
        jsonObject["oldHits"] = oldHits?.toJsonObject()
        jsonObject["currentHit"] = currentHit?.toJsonObject()
        return jsonObject
    }
}
