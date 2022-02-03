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
        jsonObject["attributes"] = CastUtils.fixDoublePrecisionIssue(values: attributes)
        return jsonObject
    }
}
