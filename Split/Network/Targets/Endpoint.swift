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
    private (set) var body: Data?

    private init(baseUrl: URL, path: String) {
        self.url = baseUrl.appendingPathComponent(path)
        self.method = .get
    }

    struct Builder {
        private var endpoint: Endpoint

        init(baseUrl: URL, path: String) {
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

        func set(body: Data) -> Self {
            endpoint.body = body
            return self
        }

        func setBody(withJson jsonBody: String) {
            endpoint.body = jsonBody.data(using: .utf8)
        }
    }
}
