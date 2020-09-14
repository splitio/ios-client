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
    var results: [SseAuthenticationResult]?
    private var resultIndex = 0

    func authenticate(userKey: String) -> SseAuthenticationResult {
        self.userKey = userKey
        let result = results![resultIndex]
        if resultIndex < results!.count - 1 {
            resultIndex+=1
        }
        return result
    }
}
