//
//  SplitFactoryStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 06/05/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitFactoryStub: SplitFactory {
    var client: SplitClient

    var manager: SplitManager

    var version: String
    var apiKey: String

    var userConsent: UserConsent {
        return .granted
    }

    init(apiKey: String) {
        self.apiKey = apiKey
        self.client = SplitClientStub()
        self.manager = SplitManagerStub()
        self.version = "0.0.0-stub"
    }

    func client(key: Key) -> SplitClient {
        return client
    }

    func client(matchingKey: String) -> SplitClient {
        return client
    }

    func client(matchingKey: String, bucketingKey: String?) -> SplitClient {
        return client
    }

    func setUserConsent(enabled: Bool) {}
}
