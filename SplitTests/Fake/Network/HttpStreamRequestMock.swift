//
//  HttpStreamRequestMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 13/07/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class HttpStreamRequestMock: HttpStreamRequest {
    var pinnedCredentialFail: Bool = false

    var responseHandler: ResponseHandler?
    var incomingDataHandler: IncomingDataHandler?
    var closeHandler: CloseHandler?
    var errorHandler: ErrorHandler?
    var closeExpectation: XCTestExpectation?

    var closeCalled = false

    var identifier: Int = 0

    var url: URL = .init(string: "www.split.com")!

    var method: HttpMethod = .get

    var parameters: HttpParameters?

    var headers: HttpHeaders = [:]

    var body: Data?

    var responseCode: Int = 0

    func send() {}

    func close() {
        closeCalled = true
        if let exp = closeExpectation {
            exp.fulfill()
        }
    }

    func setResponse(code: Int) {
        if let handler = responseHandler {
            handler(HttpResponse(code: code))
        }
    }

    func notifyIncomingData(_ data: Data) {
        if let handler = incomingDataHandler {
            handler(data)
        }
    }

    func complete(error: HttpError?) {
        if let error = error, let errorHandler = errorHandler {
            errorHandler(error)
            return
        }

        if let handler = closeHandler {
            handler()
        }
    }

    func getResponse(
        responseHandler: @escaping ResponseHandler,
        incomingDataHandler: @escaping IncomingDataHandler,
        closeHandler: @escaping CloseHandler,
        errorHandler: @escaping ErrorHandler) -> Self {
        self.responseHandler = responseHandler
        self.incomingDataHandler = incomingDataHandler
        self.closeHandler = closeHandler
        self.errorHandler = errorHandler
        return self
    }

    func notifyPinnedCredentialFail() {}
}
