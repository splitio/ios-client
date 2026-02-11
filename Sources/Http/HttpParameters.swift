//
//  HttpParameters.swift
//  Http
//

import Foundation

public struct HttpParameters: Sendable {
    public let order: [String]
    public let values: [String: HttpParameterValue]

    public init(values: [String: HttpParameterValue]) {
        self.values = values
        self.order = Array(values.keys)
    }

    /// Builds parameters from an ordered list (order preserved).
    public init(_ parameters: [HttpParameter]) {
        var order: [String] = []
        var values: [String: HttpParameterValue] = [:]
        for item in parameters {
            order.append(item.key)
            values[item.key] = item.value
        }
        self.order = order
        self.values = values
    }

    /// Convenience for [String: String] (e.g. from SseClient).
    public init(stringValues: [String: String]) {
        self.values = stringValues.mapValues { .string($0) }
        self.order = Array(stringValues.keys)
    }

    public subscript(key: String) -> HttpParameterValue? {
        values[key]
    }
}
