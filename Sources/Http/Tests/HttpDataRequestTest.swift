//  HttpDataRequestTest
//  Copyright © 2024 Split. All rights reserved.

import Foundation
import XCTest
@testable import Http

class HttpDataRequestTest: XCTestCase {

    var httpSession: HttpSessionMock!
    let url = URL(string: "http://split.com/api")!

    override func setUp() {
        httpSession = HttpSessionMock()
    }

    // MARK: - Data Accumulation Tests

    func testNotifyIncomingDataAccumulatesChunks() throws {
        let request = try DefaultHttpDataRequest(
            session: httpSession,
            url: url,
            method: .get,
            parameters: nil,
            headers: nil,
            body: nil
        )

        XCTAssertNil(request.data)

        request.notifyIncomingData(Data("chunk1".utf8))
        request.notifyIncomingData(Data("chunk2".utf8))
        request.notifyIncomingData(Data("chunk3".utf8))

        XCTAssertEqual("chunk1chunk2chunk3", String(data: request.data!, encoding: .utf8))
    }

    // MARK: - Completion Flow Tests

    func testCompletionHandlerCalledOnSuccessWithAccumulatedData() throws {
        let request = try DefaultHttpDataRequest(
            session: httpSession,
            url: url,
            method: .get,
            parameters: nil,
            headers: nil,
            body: nil
        )

        let expectation = XCTestExpectation(description: "completion called")
        var receivedResponse: HttpResponse?

        _ = request.getResponse(completionHandler: { response in
            receivedResponse = response
            expectation.fulfill()
        }, errorHandler: { _ in
            XCTFail("Error handler should not be called")
        })

        request.setResponse(code: 200)
        request.notifyIncomingData(Data("response data".utf8))
        request.complete(error: nil)

        wait(for: [expectation], timeout: 5)

        XCTAssertNotNil(receivedResponse)
        XCTAssertTrue(receivedResponse!.isSuccess)
        XCTAssertEqual("response data", String(data: receivedResponse!.data!, encoding: .utf8))
    }

    func testErrorHandlerCalledOnError() throws {
        let request = try DefaultHttpDataRequest(
            session: httpSession,
            url: url,
            method: .get,
            parameters: nil,
            headers: nil,
            body: nil
        )

        let expectation = XCTestExpectation(description: "error called")
        var receivedError: HttpError?

        _ = request.getResponse(completionHandler: { _ in
            XCTFail("Completion handler should not be called")
        }, errorHandler: { error in
            receivedError = error
            expectation.fulfill()
        })

        request.complete(error: .serverUnavailable)

        wait(for: [expectation], timeout: 5)

        XCTAssertEqual(HttpError.serverUnavailable, receivedError)
    }

    // MARK: - Pinned Credential Fail Tests

    func testPinnedCredentialFailOverridesInternalCodeOnError() throws {
        let request = try DefaultHttpDataRequest(
            session: httpSession,
            url: url,
            method: .get,
            parameters: nil,
            headers: nil,
            body: nil
        )

        let expectation = XCTestExpectation(description: "error called")
        var receivedError: HttpError?

        _ = request.getResponse(completionHandler: { _ in
            XCTFail("Completion handler should not be called")
        }, errorHandler: { error in
            receivedError = error
            expectation.fulfill()
        })

        request.notifyPinnedCredentialFail()
        request.complete(error: .clientRelated(code: 401, internalCode: 0))

        wait(for: [expectation], timeout: 5)

        // Pinning fail should override the internal code
        XCTAssertEqual(InternalHttpErrorCode.pinningValidationFail, receivedError?.internalCode)
    }

    func testPinnedCredentialFailSetsInternalCodeOnSuccessResponse() throws {
        let request = try DefaultHttpDataRequest(
            session: httpSession,
            url: url,
            method: .get,
            parameters: nil,
            headers: nil,
            body: nil
        )

        let expectation = XCTestExpectation(description: "completion called")
        var receivedResponse: HttpResponse?

        _ = request.getResponse(completionHandler: { response in
            receivedResponse = response
            expectation.fulfill()
        }, errorHandler: { _ in
            XCTFail("Error handler should not be called")
        })

        request.notifyPinnedCredentialFail()
        request.setResponse(code: 200)
        request.complete(error: nil)

        wait(for: [expectation], timeout: 5)

        // Even on success, pinning fail should be reported via internal code
        XCTAssertEqual(InternalHttpErrorCode.pinningValidationFail, receivedResponse?.internalCode)
    }
}
