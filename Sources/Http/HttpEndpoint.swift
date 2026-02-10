//
//  HttpEndpoint.swift
//  Http
//

import Foundation

/// Minimal request descriptor: URL, method, and headers.
/// Use this from the host app or build from your own Endpoint type.
public struct HttpEndpoint: Sendable {
    public var url: URL
    public var method: HttpMethod
    public var headers: [String: String]

    public init(url: URL, method: HttpMethod = .get, headers: [String: String] = [:]) {
        self.url = url
        self.method = method
        self.headers = headers
    }
}
