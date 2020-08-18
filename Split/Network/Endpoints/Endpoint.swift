//
//  Endpoint.swift
// Split
//
// Created by Javier L. Avrudsky on 13/05/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

class Endpoint {

    private (set) var url: URL
    private (set) var method: HttpMethod
    private (set) var headers = [String: String]()

    private init(baseUrl: URL, path: String?) {
        if let path = path {
            self.url = baseUrl.appendingPathComponent(path)
        } else {
            self.url = baseUrl
        }
        self.method = .get
    }

    static func builder(baseUrl: URL, path: String? = nil) -> Builder {
        return Builder(baseUrl: baseUrl, path: path)
    }

    struct Builder {
        private var endpoint: Endpoint

        init(baseUrl: URL, path: String?) {
            endpoint = Endpoint(baseUrl: baseUrl, path: path)
        }

        func add(header: String, withValue value: String) -> Self {
            endpoint.headers[header] = value
            return self
        }

        func add(headers: [String: String]) -> Self {
            for (header, value) in headers {
                endpoint.headers[header] = value
            }
            return self
        }

        func set(method: HttpMethod) -> Self {
            endpoint.method = method
            return self
        }

        func build() -> Endpoint {
            return endpoint
        }
    }
}
