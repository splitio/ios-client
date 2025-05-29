//
//  HttpParameters.swift
//  Split
//
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

class HttpParameters: ExpressibleByDictionaryLiteral {
    let order: [String]?
    let values: [String: Any]

    init(values: [String: Any]) {
        self.values = values
        self.order = nil
    }

    init(_ parameters: [HttpParameter]) {
        var order: [String] = []
        self.values = parameters.reduce(into: [:]) { dict, item in
            if item.value != nil {
                dict[item.key] = item.value
            }
            order.append(item.key)
        }
        self.order = order
    }

    required init(dictionaryLiteral elements: (String, Any)...) {
        self.values = Dictionary(uniqueKeysWithValues: elements)
        self.order = nil
    }

    subscript(key: String) -> Any? {
        return values[key]
    }
}
