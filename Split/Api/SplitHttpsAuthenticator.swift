//
//  SplitHttpsAuthenticator.swift
//  Split
//
//  Created by Javier Avrudsky on 05-Apr-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
@objc public protocol SplitHttpsAuthenticator: Sendable {
    @objc(authenticateSession:challenge:completionHandler:)
    func authenticate(session: URLSession,
                      challenge: URLAuthenticationChallenge,
                      completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}
