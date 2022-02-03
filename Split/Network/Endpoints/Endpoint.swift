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

    private init(baseUrl: URL, path: String?, isPathEncoded: Bool = false, defaultQueryString: String? = nil) {

        var comp = URLComponents()
        comp.host = baseUrl.host
        comp.scheme = baseUrl.scheme
        comp.port = baseUrl.port
        if let path = path {
            let newPath = "\(baseUrl.path)/\(path)"
            if isPathEncoded {
                comp.percentEncodedPath = newPath
            } else {
                comp.path = newPath
            }
        } else {
            comp.path = baseUrl.path
        }

        if var queryString = defaultQueryString, let from = queryString.firstIndex(of: "&") {
            let upperLimit = queryString.index(from, offsetBy: 1)
            queryString = queryString.replacingOccurrences(of: "&", with: "",
                                                           options: .caseInsensitive, range: from..<upperLimit)
            comp.query = queryString
        }
        self.url = comp.url ?? baseUrl
        self.method = .get
    }

    static func builder(baseUrl: URL, path: String? = nil, defaultQueryString: String? = nil) -> Builder {
        return Builder(baseUrl: baseUrl, path: path, isPathEncoded: false, defaultQueryString: defaultQueryString)
    }

    static func builder(baseUrl: URL, encodedPath: String, defaultQueryString: String? = nil) -> Builder {
        return Builder(baseUrl: baseUrl, path: encodedPath, isPathEncoded: true, defaultQueryString: defaultQueryString)
    }

    struct Builder {
        private var endpoint: Endpoint

        init(baseUrl: URL, path: String?, isPathEncoded: Bool, defaultQueryString: String? = nil) {
            endpoint = Endpoint(baseUrl: baseUrl, path: path,
                                isPathEncoded: isPathEncoded, defaultQueryString: defaultQueryString)
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
