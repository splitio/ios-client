//
//  SplitHttpClientAdapter.swift
//  Split
//
//  Adapts Split's Endpoint-based API to the Http module.
//

import Foundation
import Http

/// Split's HTTP client protocol: takes Endpoint, returns Http module request types.
protocol HttpClient {
    func sendRequest(endpoint: Endpoint, parameters: HttpParameters?, headers: [String: String]?, body: Data?) throws -> HttpDataRequest
    func sendStreamRequest(endpoint: Endpoint, parameters: HttpParameters?, headers: [String: String]?) throws -> HttpStreamRequest
}

extension HttpClient {
    func sendRequest(endpoint: Endpoint, parameters: HttpParameters? = nil, headers: [String: String]? = nil) throws -> HttpDataRequest {
        try sendRequest(endpoint: endpoint, parameters: parameters, headers: headers, body: nil)
    }
}

/// Builds the Http session config used by the default client (set by DefaultSplitFactory).
enum SplitHttpConfig {
    static let kDefaultConnectionTimeout: TimeInterval = 30

    nonisolated(unsafe) static var connectionTimeOut: TimeInterval = kDefaultConnectionTimeout
    nonisolated(unsafe) static var pinChecker: TlsPinChecker?
    nonisolated(unsafe) static var httpsAuthenticator: SplitHttpsAuthenticator?
    nonisolated(unsafe) static var notificationHelper: NotificationHelper?

    static func makeHttpSessionConfig() -> Http.HttpSessionConfig {
        let authHandler: HttpAuthChallengeHandler? = (pinChecker != nil || httpsAuthenticator != nil)
            ? SplitAuthChallengeHandler(pinChecker: pinChecker, httpsAuthenticator: httpsAuthenticator, notificationHelper: notificationHelper)
            : nil
        return HttpSessionConfig(connectionTimeOut: connectionTimeOut, authChallengeHandler: authHandler)
    }
}

/// Default HTTP client: delegates to the Http module and converts Endpoint → HttpEndpoint.
class DefaultHttpClient: @unchecked Sendable {
    #if swift(>=6.0)
    nonisolated(unsafe) static let shared: HttpClient = DefaultHttpClient()
    #else
    static let shared: HttpClient = DefaultHttpClient()
    #endif

    private let inner: Http.DefaultHttpClient

    init(configuration: Http.HttpSessionConfig? = nil, session: Http.HttpSession? = nil, requestManager: Http.HttpRequestManager? = nil) {
        let config = configuration ?? SplitHttpConfig.makeHttpSessionConfig()
        self.inner = Http.DefaultHttpClient(configuration: config, session: session, requestManager: requestManager)
    }
}

extension DefaultHttpClient: HttpClient {
    func sendRequest(endpoint: Endpoint, parameters: HttpParameters?, headers: [String: String]?, body: Data?) throws -> HttpDataRequest {
        try inner.sendRequest(endpoint: endpoint.asHttpEndpoint, parameters: parameters, headers: headers, body: body)
    }

    func sendStreamRequest(endpoint: Endpoint, parameters: HttpParameters?, headers: [String: String]?) throws -> HttpStreamRequest {
        try inner.sendStreamRequest(endpoint: endpoint.asHttpEndpoint, parameters: parameters, headers: headers)
    }
}
