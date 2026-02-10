//
//  HttpParameter.swift
//  Http
//

import Foundation

public struct HttpParameter: Sendable {
    public let key: String
    public let value: Any?

    public init(key: String, value: Any? = nil) {
        self.key = key
        self.value = value
    }
}
