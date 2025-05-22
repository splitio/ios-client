//
//  RestClient.swift
//  Split
//
//  Created by Javier Avrudsky on 22-Sep-2020.
//  Copyright © 2020 Split Software. All rights reserved.
//

import Foundation

protocol RestClient {
    func isServerAvailable(_ url: URL) -> Bool
    func isServerAvailable(path url: String) -> Bool
    func isEventsServerAvailable() -> Bool
    func isSdkServerAvailable() -> Bool
}

protocol SplitApiRestClient: RestClientSplitChanges, RestClientImpressions,
                             RestClientTrackEvents, RestClientSseAuthenticator, RestClientTelemetryStats,
                             RestClientImpressionsCount, RestClientTelemetryConfig, RestClientUniqueKeys,
                             RestClientMySegments {}

protocol HostReachabilityChecker {
    func isReachable(path url: String) -> Bool
}

class ReachabilityWrapper: HostReachabilityChecker {
    func isReachable(path url: String) -> Bool {
        #if os(watchOS)
            return true // for now
        #else
        if let reachabilityManager = NetworkReachabilityManager(host: url) {
            return reachabilityManager.isReachable
        }
        return false
        #endif
    }
}

class DefaultRestClient: SplitApiRestClient {
    // MARK: - Private Properties
    private let httpClient: HttpClient
    let endpointFactory: EndpointFactory
    private let reachabilityChecker: HostReachabilityChecker

    // MARK: - Designated Initializer
    init(httpClient: HttpClient = RestClientConfiguration.httpClient,
         endpointFactory: EndpointFactory,
         reachabilityChecker: HostReachabilityChecker = ReachabilityWrapper()) {
        self.httpClient = httpClient
        self.endpointFactory = endpointFactory
        self.reachabilityChecker = reachabilityChecker
    }

    func execute<T>(endpoint: Endpoint,
                    parameters: HttpParameters? = nil,
                    body: Data? = nil,
                    headers: HttpHeaders? = nil,
                    customDecoder: ((Data) throws -> T)? = nil,
                    customFailureHandler: ((Int) throws -> Error?)? = nil,
                    completion: @escaping (DataResult<T>) -> Void) where T: Decodable {

        do {
        _ = try httpClient.sendRequest(
                        endpoint: endpoint,
                        parameters: parameters,
                        headers: headers,
                        body: body)
            .getResponse(completionHandler: { response in
            switch response.result {
            case .success(let json):
                if json.isNull() {
                    completion(DataResult { return nil })
                    return
                }

                do {
                    if let customDecoder = customDecoder {
                        // Use the custom decoder if provided
                        if let parsedObject = try json.decodeWith(customDecoder) {
                            completion(DataResult { return parsedObject })
                        } else {
                            completion(DataResult { return nil })
                        }
                    } else {
                        // Use the default decoder
                        let parsedObject = try json.decode(T.self)
                        completion(DataResult { return parsedObject })
                    }
                } catch {
                    completion(DataResult { throw error })
                }
            case .failure:
                completion(DataResult {
                    // Try custom error handling first, then fall back to default
                    if let customError = try customFailureHandler?(response.code) {
                        throw customError
                    }

                    // Default error handling
                    if response.code == HttpCode.uriTooLong {
                        throw HttpError.uriTooLong
                    }
                    if response.code >= HttpCode.badRequest, response.code < HttpCode.internalServerError {
                        throw HttpError.clientRelated(code: response.code, internalCode: InternalHttpErrorCode.noCode)
                    }
                    throw HttpError.unknown(code: response.code, message: "unknown")
                })
            }
            }, errorHandler: { error in
                completion(DataResult {
                    // Try custom error handling first, then fall back to the original error
                    if let customError = try customFailureHandler?(error.code) {
                        throw customError
                    }
                    throw error
                })
            })
        } catch HttpError.couldNotCreateRequest(let message) {
            Logger.e("An error has ocurred while sending request: \(message)" )
        } catch {
            Logger.e("Unexpected error while sending request")
        }
    }
}

extension DefaultRestClient: RestClient {
    func isServerAvailable(_ url: URL) -> Bool {
        return self.isServerAvailable(path: url.absoluteString)
    }

    func isServerAvailable(path url: String) -> Bool {
        return reachabilityChecker.isReachable(path: url)
    }

    func isEventsServerAvailable() -> Bool {
        return self.isServerAvailable(endpointFactory.serviceEndpoints.eventsEndpoint)
    }

    func isSdkServerAvailable() -> Bool {
        return self.isServerAvailable(endpointFactory.serviceEndpoints.sdkEndpoint)
    }
}
