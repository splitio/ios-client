//
//  HttpAuthenticator.swift
//  Http
//
//  Protocol for handling HTTPS authentication challenges.
//

import Foundation

/// A protocol for handling HTTPS authentication challenges.
///
/// Implementations can provide custom certificate validation,
/// client certificate authentication, or other challenge responses.
public protocol HttpAuthenticator: Sendable {
    func authenticate(session: URLSession,
                      challenge: URLAuthenticationChallenge,
                      completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}
