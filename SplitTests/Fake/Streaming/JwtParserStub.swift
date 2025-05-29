//
//  JwtParserStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 10/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

struct JwtParserStub: JwtTokenParser {
    var token: JwtToken?
    var error: JwtTokenError?

    init(token: JwtToken) {
        self.token = token
    }

    init(error: JwtTokenError) {
        self.error = error
    }

    func parse(raw: String?) throws -> JwtToken {
        if let e = error {
            throw e
        }
        return token!
    }
}
