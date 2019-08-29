//
//  Endpoint.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation

protocol Target {
    var sdkBaseUrl: URL { get }
    var eventsBaseURL: URL { get }
    var apiKey: String? { get }
    var commonHeaders: [String: String]? { get }
    var method: HttpMethod { get }
    var url: URL { get }
    var body: Data? { get }
    var parameters: [String: Any]? { get }
    var errorSanitizer: (JSON, Int) -> HttpResult<JSON> { get }

    func append(value: String, forHttpHeader headerKey: String)
    func setBody(data: Data)
    func setBody(json: String)
}
