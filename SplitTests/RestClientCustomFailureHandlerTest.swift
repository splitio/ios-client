//
//  RestClientCustomFailureHandlerTest.swift
//  SplitTests
//
//  Created on 13/05/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import XCTest
@testable import Split

class RestClientCustomFailureHandlerTest: XCTestCase {
    
    private var httpSession: HttpSessionMock!
    private var requestManager: HttpRequestManagerMock!
    private var httpClient: HttpClient!
    private var restClient: DefaultRestClient!
    
    override func setUp() {
        super.setUp()
        httpSession = HttpSessionMock()
        requestManager = HttpRequestManagerMock()
        httpClient = DefaultHttpClient(session: httpSession, requestManager: requestManager)
        let serviceEndpoints = ServiceEndpoints.builder()
            .set(sdkEndpoint: "https://sdk.split-test.io")
            .set(eventsEndpoint: "https://events.split-test.io").build()
        let endpointFactory = EndpointFactory(serviceEndpoints: serviceEndpoints, apiKey: "dummy-key", splitsQueryString: "")
        restClient = DefaultRestClient(httpClient: httpClient, endpointFactory: endpointFactory)
    }

    override func tearDown() {
        httpSession = nil
        requestManager = nil
        restClient = nil
        super.tearDown()
    }
    
    func testExecuteWithCustomFailureHandler() {
        let expectation = XCTestExpectation(description: "API call completes with error")
        var result: TestModel?
        var error: Error?
        var customErrorHandled = false
        
        // Custom failure handler that checks for HTTP 400 and returns a custom error
        let customFailureHandler: (Int) throws -> Error? = { statusCode in
            if statusCode == HttpCode.badRequest {
                customErrorHandled = true
                return NSError(domain: "CustomErrorDomain", code: 999, userInfo: [NSLocalizedDescriptionKey: "Custom error message"])
            }
            return nil
        }
        
        restClient.execute(
            endpoint: restClient.endpointFactory.splitChangesEndpoint,
            parameters: nil,
            headers: nil,
            customFailureHandler: customFailureHandler,
            completion: { (dataResult: DataResult<TestModel>) in
                do {
                    result = try dataResult.unwrap()
                    expectation.fulfill()
                } catch let err {
                    error = err
                    expectation.fulfill()
                }
            })
        
        // Simulate HTTP 400 response
        requestManager.append(data: Data(), to: 1)
        _ = requestManager.set(responseCode: HttpCode.badRequest, to: 1)
        
        wait(for: [expectation], timeout: 1)
        
        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertNil(result)
        XCTAssertNotNil(error)
        XCTAssertTrue(customErrorHandled)
        
        // Verify we got our custom error
        if let nsError = error as? NSError {
            XCTAssertEqual(nsError.domain, "CustomErrorDomain")
            XCTAssertEqual(nsError.code, 999)
            XCTAssertEqual(nsError.localizedDescription, "Custom error message")
        } else {
            XCTFail("Expected NSError but got \(String(describing: error))")
        }
    }
    
    func testExecuteWithCustomFailureHandlerFallback() {
        let expectation = XCTestExpectation(description: "API call completes with error")
        var result: TestModel?
        var error: Error?
        var httpError: HttpError?
        
        // Custom failure handler that returns a different error for HTTP 400 but nil for HTTP 500
        let customFailureHandler: (Int) throws -> Error? = { statusCode in
            if statusCode == HttpCode.badRequest {
                return NSError(domain: "CustomErrorDomain", code: 999, userInfo: [NSLocalizedDescriptionKey: "Custom error message"])
            }
            // Return nil for HTTP 500 to fall back to default error handling
            return nil
        }
        
        restClient.execute(
            endpoint: restClient.endpointFactory.splitChangesEndpoint,
            parameters: nil,
            headers: nil,
            customFailureHandler: customFailureHandler,
            completion: { (dataResult: DataResult<TestModel>) in
                do {
                    result = try dataResult.unwrap()
                    expectation.fulfill()
                } catch let err {
                    error = err
                    if let httpErr = err as? HttpError {
                        httpError = httpErr
                    }
                    expectation.fulfill()
                }
            })
        
        // Simulate HTTP 500 response
        requestManager.append(data: Data(), to: 1)
        _ = requestManager.set(responseCode: HttpCode.internalServerError, to: 1)
        
        wait(for: [expectation], timeout: 1)
        
        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertNil(result)
        XCTAssertNotNil(error)
        XCTAssertNotNil(httpError)
        
        // Verify we got the default unknown error for HTTP 500
        if case .unknown(let code, _)? = httpError {
            XCTAssertEqual(code, HttpCode.internalServerError)
        } else {
            XCTFail("Expected HttpError.unknown but got \(String(describing: httpError))")
        }
    }
}

// Test model
struct TestModel: Decodable {
    let id: Int
    let name: String
}
