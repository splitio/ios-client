//  HttpAuthenticator
//  Protocol for handling HTTPS authentication challenges.
//  Copyright © 2024 Split. All rights reserved.

import Foundation

public protocol HttpAuthenticator: Sendable {
    func authenticate(session: URLSession,
                      challenge: URLAuthenticationChallenge,
                      completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}
