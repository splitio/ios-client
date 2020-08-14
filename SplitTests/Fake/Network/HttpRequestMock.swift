//
//  HttpRequestMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 23/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class HttpRequestMock: HttpRequest {
    let identifier: Int

    var url: URL

    var method: HttpMethod = .get

    var parameters: HttpParameters?

    var headers: HttpHeaders = [:]

    var response: HTTPURLResponse?

    var retryTimes: Int = 0

    init(identifier: Int) {
        self.identifier = identifier
        self.url = URL(string: "http://dummy.com")!
    }

    func setResponse(_ response: HTTPURLResponse) {
    }

    func send() {
    }

    func retry() {
    }

    func complete(withError error: Error?) {
    }


}
