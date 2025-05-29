//
//  RestClient+SplitChanges.swift
//  Split
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation

/// A handler for specific error conditions in Split Changes requests
fileprivate class SplitChangesErrorHandler {
    private let serviceEndpoints: ServiceEndpoints

    init(serviceEndpoints: ServiceEndpoints) {
        self.serviceEndpoints = serviceEndpoints
    }

    /// Handles HTTP errors for Split Changes requests
    /// - Parameters:
    ///   - statusCode: The HTTP status code
    ///   - spec: The spec version used in the request
    /// - Returns: A specific HttpError if the conditions match, or nil to fall back to default error handling
    func handleError(statusCode: Int, spec: String) -> Error? {
        if statusCode == HttpCode.badRequest,
           serviceEndpoints.isCustomSdkEndpoint,
           spec == "1.3" {
            return HttpError.outdatedProxyError(code: statusCode, spec: spec)
        }
        // Return nil to fall back to default error handling
        return nil
    }
}

protocol RestClientSplitChanges: RestClient {
    func getSplitChanges(
        since: Int64,
        rbSince: Int64?,
        till: Int64?,
        headers: HttpHeaders?,
        spec: String,
        completion: @escaping (DataResult<TargetingRulesChange>) -> Void)
}

extension DefaultRestClient: RestClientSplitChanges {
    func getSplitChanges(
        since: Int64,
        rbSince: Int64?,
        till: Int64?,
        headers: HttpHeaders?,
        spec: String = Spec.flagsSpec,
        completion: @escaping (DataResult<TargetingRulesChange>) -> Void) {
        let errorHandler = SplitChangesErrorHandler(serviceEndpoints: endpointFactory.serviceEndpoints)

        execute(
            endpoint: endpointFactory.splitChangesEndpoint,
            parameters: buildParameters(since: since, rbSince: rbSince, till: till, spec: spec),
            headers: headers,
            customDecoder: TargetingRulesChangeDecoder.decode,
            customFailureHandler: { statusCode in
                errorHandler.handleError(statusCode: statusCode, spec: spec)
            },
            completion: completion)
    }

    private func buildParameters(
        since: Int64,
        rbSince: Int64?,
        till: Int64?,
        spec: String) -> HttpParameters {
        var parameters: [HttpParameter] = []
        if !spec.isEmpty {
            parameters.append(HttpParameter(key: "s", value: spec))
        }

        parameters.append(HttpParameter(key: "since", value: since))
        if let rbSince = rbSince {
            parameters.append(HttpParameter(key: "rbSince", value: rbSince))
        }
        parameters.append(HttpParameter(key: "sets"))
        parameters.append(HttpParameter(key: "names"))
        parameters.append(HttpParameter(key: "prefixes"))

        if let till = till {
            parameters.append(HttpParameter(key: "till", value: till))
        }

        return HttpParameters(parameters)
    }
}
