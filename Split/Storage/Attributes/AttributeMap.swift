//
//  AttributeMap.swift
//  Split
//
//  Created by Javier Avrudsky on 08-Nov-2021.
//  Copyright © 2021 Split. All rights reserved.
//
//  This class is intented to wrap attributes in order to make them
//  easily parsed as Json to store in DB

import Foundation

class AttributeMap: DynamicCodable {

    var attributes: [String: Any]

    init(attributes: [String: Any]) {
        self.attributes = attributes
    }

    required init(jsonObject: Any) throws {
        let jsonObj = jsonObject as? [String: Any] ?? [:]
        attributes = jsonObj["attributes"] as? [String: Any] ?? [:]
    }

    func toJsonObject() -> Any {
        var jsonObject = [String: Any]()
        var parsedAttributes: [String: Any]?
        parsedAttributes = [String: Any]()
        for (propKey, propValue) in attributes {
            // Workaround to avoid lost of precision of Decimal(double:) constructor
            if !(propValue is Bool || propValue is String), let doubleValue = propValue as? Double {
                parsedAttributes?[propKey] = Decimal(string: String(doubleValue))
            } else {
                parsedAttributes?[propKey] = propValue
            }
        }
        jsonObject["attributes"] = parsedAttributes
        return jsonObject
    }
}
