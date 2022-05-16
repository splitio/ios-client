//
//  SseAuthenticator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 07/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

///
/// Used when HTTP response decoding
///
struct SseAuthToken: Decodable {
    let issuedAt: Int
    let expirationTime: Int64
    let channels: String

    enum CodingKeys: String, CodingKey {
        case issuedAt = "iat"
        case expirationTime = "exp"
        case channels = "x-ably-capability"
    }
}

///
/// This is the JWT after being parsed and ready to use for
/// SSE connection
///
struct JwtToken {
    let issuedAt: Int
    let expirationTime: Int64
    let channels: [String]
    let rawToken: String
}

///
/// SSE authenticator component returns this
/// struct when authentication process is finished
///
struct SseAuthenticationResult {
    let success: Bool
    let errorIsRecoverable: Bool
    let pushEnabled: Bool
    let rawToken: String?
    let sseConnectionDelay: Int64
}

///
/// Hits the Streaming authentication server
/// to get streaming status for API key
///
protocol SseAuthenticator {
    func authenticate(userKeys: [String]) -> SseAuthenticationResult
}

class DefaultSseAuthenticator: SseAuthenticator {

    private let restClient: RestClientSseAuthenticator
    private let syncHelper: SyncHelper
    private let resource: Resource = .token

    init(restClient: RestClientSseAuthenticator,
         syncHelper: SyncHelper) {
        self.restClient = restClient
        self.syncHelper = syncHelper
    }

    func authenticate(userKeys: [String]) -> SseAuthenticationResult {
        let semaphore = DispatchSemaphore(value: 0)
        var requestResult: DataResult<SseAuthenticationResponse>?

        guard (try? syncHelper.checkEndpointReachability(restClient: restClient, resource: resource)) != nil else {
            return errorResult(recoverable: true)
        }

        restClient.authenticate(userKeys: userKeys) { result in
            requestResult = result
            semaphore.signal()
        }
        semaphore.wait()

        let response: SseAuthenticationResponse
        let startTime = Stopwatch.now()
        do {
            if let resp = try requestResult?.unwrap() {
                response = resp
                syncHelper.recordTelemetry(resource: resource, startTime: startTime)
            } else {
                return errorResult(recoverable: true)
            }

        } catch HttpError.clientRelated(let httpCode) {
            syncHelper.recordHttpError(code: httpCode, resource: resource, startTime: startTime)
            return errorResult(recoverable: false)
        } catch {
            _ = syncHelper.handleError(error, resource: resource, startTime: startTime)
            return errorResult(recoverable: true)
        }

        if response.pushEnabled, response.token ?? "" == "" {
            return errorResult(recoverable: true)
        }
        let connectionDelay = response.sseConnectionDelay ?? ServiceConstants.defaultSseConnectionDelayInSecs
        return SseAuthenticationResult(success: true, errorIsRecoverable: false,
                                       pushEnabled: response.pushEnabled, rawToken: response.token,
                                       sseConnectionDelay: connectionDelay)
    }
}

// MARK: Private
extension DefaultSseAuthenticator {
    private func errorResult(recoverable: Bool) -> SseAuthenticationResult {
        return SseAuthenticationResult(success: false, errorIsRecoverable: recoverable,
                                       pushEnabled: false, rawToken: nil, sseConnectionDelay: 0)
    }
}
