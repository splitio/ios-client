//
//  HttpRequestMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 10/07/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class HttpRequestMock: HttpRequest {
    var pinnedCredentialFail: Bool = false

    func notifyPinnedCredentialFail() {}

    var identifier: Int

    var url: URL = .init(string: "http://split.com")!

    var method: HttpMethod = .get

    var parameters: HttpParameters?

    var headers: HttpHeaders = [:]

    var body: Data?

    var responseCode: Int = -1

    init(identifier: Int) {
        self.identifier = identifier
    }

    func send() {}

    func setResponse(code: Int) {}

    func notifyIncomingData(_ data: Data) {}

    func complete(error: HttpError?) {}
}
