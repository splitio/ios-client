//
//  Endpoint+HttpEndpoint.swift
//  Split
//

import Foundation
import Http

extension Endpoint {
    /// Converts this Endpoint to the Http module's request descriptor.
    var asHttpEndpoint: Http.HttpEndpoint {
        Http.HttpEndpoint(url: url, method: method, headers: headers)
    }
}
