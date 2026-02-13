//
//  HttpErrorTest.swift
//  HttpTests
//
//  Copyright © 2026 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Http

class HttpErrorTest: XCTestCase {

    // MARK: - isProxyOutdatedError Tests

    func testIsProxyOutdatedErrorTrue() {
        let error = HttpError.outdatedProxyError(code: 426, spec: "1.1")
        XCTAssertTrue(error.isProxyOutdatedError())
    }

    func testIsProxyOutdatedErrorFalseForOtherErrors() {
        let errors: [HttpError] = [
            .serverUnavailable,
            .requestTimeOut,
            .uriTooLong,
            .clientRelated(code: 401, internalCode: 1),
            .couldNotCreateRequest(message: "test"),
            .unknown(code: 500, message: "test"),
            .networkLost(code: -1005)
        ]

        for error in errors {
            XCTAssertFalse(error.isProxyOutdatedError(), "Expected \(error) to not be a proxy outdated error")
        }
    }

    // MARK: - Internal Code Tests

    func testClientRelatedReturnsInternalCode() {
        let error = HttpError.clientRelated(code: 401, internalCode: 42)
        XCTAssertEqual(42, error.internalCode)
    }

    func testOtherErrorsReturnNoCodeAsInternalCode() {
        let errors: [HttpError] = [
            .serverUnavailable,
            .requestTimeOut,
            .uriTooLong,
            .couldNotCreateRequest(message: "test"),
            .unknown(code: 500, message: "test"),
            .outdatedProxyError(code: 426, spec: "1.1"),
            .networkLost(code: -1005)
        ]

        for error in errors {
            XCTAssertEqual(InternalHttpErrorCode.noCode, error.internalCode, "Expected \(error) to have noCode as internal code")
        }
    }

    // MARK: - Code extraction from associated values

    func testCodeExtractionFromErrorsWithAssociatedValues() {
        // Errors that have code in associated value should return it
        XCTAssertEqual(401, HttpError.clientRelated(code: 401, internalCode: 1).code)
        XCTAssertEqual(999, HttpError.unknown(code: 999, message: "msg").code)
        XCTAssertEqual(426, HttpError.outdatedProxyError(code: 426, spec: "1.1").code)
        XCTAssertEqual(-1005, HttpError.networkLost(code: -1005).code)
    }

    func testCodeReturnsMinusOneForErrorsWithoutAssociatedCode() {
        // Errors without code in associated value should return -1
        XCTAssertEqual(-1, HttpError.serverUnavailable.code)
        XCTAssertEqual(-1, HttpError.requestTimeOut.code)
        XCTAssertEqual(-1, HttpError.uriTooLong.code)
        XCTAssertEqual(-1, HttpError.couldNotCreateRequest(message: "test").code)
    }
}
