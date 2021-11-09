//
//  EventDTO.swift
//  Split
//
//  Created by Javier Avrudsky on 06/14/2018.
//

import Foundation

class EventDTO: DynamicCodable {
    var storageId: String?
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
        if let properties = properties {
            jsonObject["properties"] = CastUtils.fixDoublePrecisionIssue(values: properties)
        }
        return jsonObject
    }
}
