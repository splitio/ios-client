//
//  EventDTO.swift
//  Split
//
//  Created by Javier Avrudsky on 06/14/2018.
//

import Foundation

class EventDTO: DynamicCodable {

    var key: String?
    var eventTypeId: String
    var trafficTypeName: String
    var value: Double?
    var timestamp: Int64?
    var properties: [String: Any]?
    var sizeInBytes: Int = 0

    init(trafficType: String, eventType: String) {
        self.trafficTypeName = trafficType
        self.eventTypeId = eventType
    }

    required init(jsonObject: Any) throws {
        let jsonObj = jsonObject as? [String: Any] ?? [:]
        key = jsonObj["key"] as? String
        eventTypeId = jsonObj["eventTypeId"] as? String ?? ""
        trafficTypeName = jsonObj["trafficTypeName"] as? String ?? ""
        value = jsonObj["value"] as? Double
        timestamp = jsonObj["timestamp"] as? Int64
        properties = jsonObj["properties"] as? [String: Any]

    }

    func toJsonObject() -> Any {
        var jsonObject = [String: Any]()
        jsonObject["key"] = key
        jsonObject["eventTypeId"] = eventTypeId
        jsonObject["trafficTypeName"] = trafficTypeName
        // Workaround to avoid lost of precision of Decimal(double:) constructor
        jsonObject["value"] = Decimal(string: String(value ?? 0))
        jsonObject["timestamp"] = timestamp
        var parsedProps: [String: Any]?
        if let properties = properties {
            parsedProps = [String: Any]()
            for (propKey, propValue) in properties {
                // Workaround to avoid lost of precision of Decimal(double:) constructor
                if !(propValue is Bool || propValue is String), let doubleValue = propValue as? Double {
                    parsedProps?[propKey] = Decimal(string: String(doubleValue))
                } else {
                    parsedProps?[propKey] = propValue
                }
            }
        }
        jsonObject["properties"] = parsedProps
        return jsonObject
    }
}
