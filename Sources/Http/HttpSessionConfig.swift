//
//  HttpSessionConfig.swift
//  Http
//

import Foundation

/// Handles URL authentication challenges (e.g. TLS pinning, custom auth).
/// The host app can implement this to plug in certificate pinning or other logic.
public protocol HttpAuthChallengeHandler: Sendable {
    func handle(
        session: URLSession,
        task: URLSessionTask,
        challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    )
}

/// Configuration for the HTTP client and session.
public class HttpSessionConfig: @unchecked Sendable {
    public static let kDefaultConnectionTimeout: TimeInterval = 30
    public static let `default` = HttpSessionConfig()

    public var connectionTimeOut: TimeInterval = kDefaultConnectionTimeout
    public var authChallengeHandler: (any HttpAuthChallengeHandler)?

    public init(
        connectionTimeOut: TimeInterval = kDefaultConnectionTimeout,
        authChallengeHandler: (any HttpAuthChallengeHandler)? = nil
    ) {
        self.connectionTimeOut = connectionTimeOut
        self.authChallengeHandler = authChallengeHandler
    }
}
