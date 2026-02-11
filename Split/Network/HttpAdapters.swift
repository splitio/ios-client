//
//  HttpAdapters.swift
//  Split
//
//  Bridges Split-specific authentication and notification types
//  to the generic protocols defined in the Http module.
//

import Foundation
#if !COCOAPODS
import Http
#endif

// MARK: - SplitHttpsAuthenticator → HttpAuthenticator

/// Wraps a ``SplitHttpsAuthenticator`` (the @objc public SDK protocol)
/// so it can be used wherever ``HttpAuthenticator`` is expected.
struct SplitAuthenticatorAdapter: HttpAuthenticator {
    let wrapped: SplitHttpsAuthenticator

    func authenticate(session: URLSession,
                      challenge: URLAuthenticationChallenge,
                      completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        wrapped.authenticate(session: session,
                             challenge: challenge,
                             completionHandler: completionHandler)
    }
}

// MARK: - NotificationHelper → HttpNotificationHandler

/// Wraps a ``NotificationHelper`` so it can be used wherever
/// ``HttpNotificationHandler`` is expected by the Http module.
struct SplitNotificationAdapter: HttpNotificationHandler {
    let helper: NotificationHelper

    func notifyPinningFailure(host: String) {
        helper.post(notification: .pinnedCredentialValidationFail, info: host as AnyObject)
    }

    func notifyPinningStatus(_ status: CertificatePinningCompleteStatus) {
        helper.post(notification: .pinnedCredentialStatus, info: status as AnyObject)
    }
}
