//
//  SseAuthenticationStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 17/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class SseAuthenticatorStub: SseAuthenticator {
    var userKey: String?
    var result: SseAuthenticationResult?

    func authenticate(userKey: String) -> SseAuthenticationResult {
        return result!
    }
}
