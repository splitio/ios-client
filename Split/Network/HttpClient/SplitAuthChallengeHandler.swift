//
//  SplitAuthChallengeHandler.swift
//  Split
//
//  Bridges Split's TLS pinning and HTTPS authenticator to the Http module.
//

import Foundation
import Http

/// Forwards URL authentication challenges to Split's pin checker and/or HTTPS authenticator.
final class SplitAuthChallengeHandler: HttpAuthChallengeHandler, @unchecked Sendable {
    private let pinChecker: TlsPinChecker?
    private let httpsAuthenticator: SplitHttpsAuthenticator?
    private let notificationHelper: NotificationHelper?

    init(pinChecker: TlsPinChecker?, httpsAuthenticator: SplitHttpsAuthenticator?, notificationHelper: NotificationHelper?) {
        self.pinChecker = pinChecker
        self.httpsAuthenticator = httpsAuthenticator
        self.notificationHelper = notificationHelper
    }

    func handle(
        session: URLSession,
        task: URLSessionTask,
        challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if let pinChecker = pinChecker {
            Logger.v("Checking pinned credentials")
            checkPins(pinChecker: pinChecker, challenge: challenge, completionHandler: completionHandler)
            return
        }
        if let authenticator = httpsAuthenticator {
            Logger.v("Triggering external HTTPS authentication handler")
            authenticator.authenticate(session: session, challenge: challenge, completionHandler: completionHandler)
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }

    private func checkPins(
        pinChecker: TlsPinChecker,
        challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let checkResult = pinChecker.check(credential: challenge)
        var finalStatus: CertificatePinningStatus

        switch checkResult {
        case .success:
            guard let serverTrust = challenge.protectionSpace.serverTrust else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                finalStatus = .failed
                break
            }
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            finalStatus = .success

        case .error, .invalidChain, .credentialNotPinned, .spkiError, .invalidCredential, .invalidParameter, .unavailableServerTrust:
            notificationHelper?.post(notification: .pinnedCredentialValidationFail, info: challenge.protectionSpace.host as AnyObject)
            completionHandler(.cancelAuthenticationChallenge, nil)
            finalStatus = .failed

        case .noServerTrustMethod, .noPinsForDomain:
            completionHandler(.performDefaultHandling, nil)
            finalStatus = .defaultHandling
        }

        notificationHelper?.post(
            notification: .pinnedCredentialStatus,
            info: CertificatePinningCompleteStatus(host: challenge.protectionSpace.host, status: finalStatus, reason: checkResult.description) as AnyObject
        )
    }
}
