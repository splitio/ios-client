//
//  HttpParameter.swift
//  Http
//

import Foundation

public struct HttpParameter: Sendable {
    public let key: String
    public let value: HttpParameterValue

    public init(key: String, value: HttpParameterValue = .none) {
        self.key = key
        self.value = value
    }
}
