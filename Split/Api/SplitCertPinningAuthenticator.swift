//
//  SplitCertPinningAuthenticator.swift
//  Split
//
//  Created by Javier Avrudsky on 05/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation


typealias AuthCompletion = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

class SplitCertPinningAuthenticator: NSObject, SplitHttpsAuthenticator {

    private let pinChecker: TlsPinChecker
    private let pins: [CredentialPin]


    /// Initializes a new instance of SplitCertPinningAuthenticator with a given pin validator.
    /// - Parameter pinValidator: An instance of PinValidator used for validating certificates.
    init(pinChecker: TlsPinChecker,
         pins: [CredentialPin]) {
        self.pinChecker = pinChecker
        self.pins = pins
    }

    /// Authenticates the session with a URL authentication challenge.
    /// - Parameters:
    ///   - session: The URL session.
    ///   - challenge: The URL authentication challenge.
    ///   - completionHandler: The completion handler to call with the authentication disposition and credential.
    func authenticate(session: URLSession,
                      challenge: URLAuthenticationChallenge,
                      completionHandler: @escaping AuthCompletion) {

        // Validate the server trust using the PinValidator
        switch pinChecker.check(credential: challenge, pins: pins) {
        case .success:
            guard let serverTrust = challenge.protectionSpace.serverTrust else {
                cancel(completionHandler)
                return
            }
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)

        case .error, .invalidChain, .credentialNotPinned, .spkiError,
                .invalidCredential, .invalidParameter, .unavailableServerTrust:
            cancel(completionHandler)

        case .noServerTrustMethod, .noPinsForDomain:
            completionHandler(.performDefaultHandling, nil)
                        return
        }
    }

    func cancel(_ completion: @escaping AuthCompletion) {
        completion(.cancelAuthenticationChallenge, nil)
    }

}
