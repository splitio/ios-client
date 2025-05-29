//
//  HttpClientMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 13/07/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class HttpClientMock: HttpClient {
    var throwOnSend = false
    var httpDataRequest: HttpDataRequest!
    var httpStreamRequest: HttpStreamRequest!
    var httpSession: HttpSession
    var streamReqExp: XCTestExpectation?
    var datasReqExp: XCTestExpectation?

    init(session: HttpSession, dataRequest: HttpDataRequest? = nil, streamRequest: HttpStreamRequest? = nil) {
        self.httpSession = session

        if let r = dataRequest {
            self.httpDataRequest = r
        } else {
            self.httpDataRequest = try! createDummyDataRequest()
        }

        if let r = streamRequest {
            self.httpStreamRequest = r
        } else {
            self.httpStreamRequest = try! createDummyStreamRequest()
        }
    }

    func sendRequest(
        endpoint: Endpoint,
        parameters: HttpParameters?,
        headers: [String: String]?,
        body: Data?) throws -> HttpDataRequest {
        if throwOnSend {
            throw HttpError.unknown(code: -1, message: "throw on send mock exception")
        }
        return httpDataRequest
    }

    func sendStreamRequest(
        endpoint: Endpoint,
        parameters: HttpParameters?,
        headers: [String: String]?) throws -> HttpStreamRequest {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let exp = self.streamReqExp {
                exp.fulfill()
            }
        }
        if throwOnSend {
            throw HttpError.unknown(code: -1, message: "throw on send mock exception")
        }
        return httpStreamRequest
    }

    private func createDummyStreamRequest() throws -> HttpStreamRequest {
        return try DefaultHttpStreamRequest(session: httpSession, url: dummyUrl(), parameters: nil, headers: nil)
    }

    private func createDummyDataRequest() throws -> HttpDataRequest {
        return try DefaultHttpDataRequest(session: httpSession, url: dummyUrl(), method: .get, headers: nil)
    }

    private func dummyUrl() -> URL {
        return URL(string: "http:www.split.com")!
    }
}
