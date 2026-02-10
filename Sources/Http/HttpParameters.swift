//
//  HttpParameters.swift
//  Http
//

import Foundation

public class HttpParameters: ExpressibleByDictionaryLiteral, @unchecked Sendable {
    public let order: [String]?
    public let values: [String: Any]

    public init(values: [String: Any]) {
        self.values = values
        self.order = nil
    }

    public init(_ parameters: [HttpParameter]) {
        var order: [String] = []
        self.values = parameters.reduce(into: [:]) { dict, item in
            if item.value != nil {
                dict[item.key] = item.value
            }
            order.append(item.key)
        }
        self.order = order
    }

    public required init(dictionaryLiteral elements: (String, Any)...) {
        self.values = Dictionary(uniqueKeysWithValues: elements)
        self.order = nil
    }

    public subscript(key: String) -> Any? {
        return values[key]
    }
}
