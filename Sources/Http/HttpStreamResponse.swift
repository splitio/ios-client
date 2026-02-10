//
//  HttpStreamResponse.swift
//  Http
//

import Foundation

public struct HttpStreamResponse: Sendable {
    public let response: HTTPURLResponse?
    public var error: Error? { result.error }
    public let data: Data?
    public let result: HttpResult<Void>

    public init(response: HTTPURLResponse?, data: Data?, result: HttpResult<Void>) {
        self.response = response
        self.data = data
        self.result = result
    }
}
