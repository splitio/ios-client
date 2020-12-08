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

    private init(baseUrl: URL, path: String?, defaultQueryString: String? = nil) {
        var url = baseUrl
        if let path = path {
            url = baseUrl.appendingPathComponent(path)
        }

        if var queryString = defaultQueryString, let from = queryString.firstIndex(of: "&") {
            let upperLimit = queryString.index(from, offsetBy: 1)
            queryString = queryString.replacingOccurrences(of: "&", with: "?",
                                                           options: .caseInsensitive, range: from..<upperLimit)
            url = URL(string: "\(url.absoluteString)\(queryString)") ?? url
        }
        self.url = url
        self.method = .get
    }

    static func builder(baseUrl: URL, path: String? = nil, defaultQueryString: String? = nil) -> Builder {
        return Builder(baseUrl: baseUrl, path: path, defaultQueryString: defaultQueryString)
    }

    struct Builder {
        private var endpoint: Endpoint

        init(baseUrl: URL, path: String?, defaultQueryString: String? = nil) {
            endpoint = Endpoint(baseUrl: baseUrl, path: path, defaultQueryString: defaultQueryString)
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
