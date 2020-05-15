//
//  Api.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation

protocol RestClient {
    func isServerAvailable(_ url: URL) -> Bool
    func isServerAvailable(path url: String) -> Bool
    func isEventsServerAvailable() -> Bool
    func isSdkServerAvailable() -> Bool
}

class DefaultRestClient {
    // MARK: - Private Properties
    private let httpClient: HttpClient
    let endpointFactory: EndpointFactory

    // MARK: - Designated Initializer
    init(httpClient: HttpClient = RestClientConfiguration.httpClient, endpointFactory: EndpointFactory) {
        self.httpClient = httpClient
        self.endpointFactory = endpointFactory
    }

    func execute<T>(endpoint: Endpoint,
                    parameters: [String: Any]? = nil,
                    body: Data? = nil,
                    completion: @escaping (DataResult<T>) -> Void) where T: Decodable {
        _ = httpClient.sendRequest(
                        endpoint: endpoint,
                        parameters: parameters,
                        headers: nil,
                        body: body)
                .getResponse(errorHandler: endpoint.errorSanitizer) { response in
            switch response.result {
            case .success(let json):
                if json.isNull() {
                    completion(DataResult { return nil })
                    return
                }

                do {
                    let parsedObject = try json.decode(T.self)
                    completion(DataResult { return parsedObject })
                } catch {
                    completion(DataResult { throw error })
                }
            case .failure(let error):
                completion(DataResult { throw error })
            }
        }
    }
}

extension DefaultRestClient: RestClient {
    func isServerAvailable(_ url: URL) -> Bool {
        return self.isServerAvailable(path: url.absoluteString)
    }

    func isServerAvailable(path url: String) -> Bool {
        if let reachabilityManager = NetworkReachabilityManager(host: url) {
            return reachabilityManager.isReachable
        }
        return false
    }

    func isEventsServerAvailable() -> Bool {
        return self.isServerAvailable(endpointFactory.serviceEndpoints.eventsEndpoint)
    }

    func isSdkServerAvailable() -> Bool {
        return self.isServerAvailable(endpointFactory.serviceEndpoints.sdkEndpoint)
    }
}
