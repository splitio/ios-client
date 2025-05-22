//
//  SplitChangesErrorHandlerTests.swift
//  SplitTests
//
//  Created on 13/05/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import XCTest
@testable import Split

class SplitChangesErrorHandlerTests: XCTestCase {
    
    private var httpSession: HttpSessionMock!
    private var requestManager: HttpRequestManagerMock!
    private var httpClient: HttpClient!
    
    override func setUp() {
        super.setUp()
        httpSession = HttpSessionMock()
        requestManager = HttpRequestManagerMock()
        httpClient = DefaultHttpClient(session: httpSession, requestManager: requestManager)
    }
    
    override func tearDown() {
        httpSession = nil
        requestManager = nil
        httpClient = nil
        super.tearDown()
    }
    
    func testSplitChangesWithOutdatedProxyError() {
        // Setup with overridden SDK endpoint
        let customEndpoint = "https://custom-sdk.split.io"
        let overriddenServiceEndpoints = ServiceEndpoints.builder().set(sdkEndpoint: customEndpoint).build()
        let overriddenFactory = EndpointFactory(serviceEndpoints: overriddenServiceEndpoints, apiKey: "dummy-api-key", splitsQueryString: "")
        let clientWithOverriddenEndpoint = DefaultRestClient(httpClient: httpClient, endpointFactory: overriddenFactory)
        
        // Specific spec version for this test
        let testSpec = "1.3"
        
        let expectation = XCTestExpectation(description: "API call completes with outdated proxy error")
        var result: TargetingRulesChange?
        var error: Error?
        var outdatedProxyError: HttpError?

        // Call getSplitChanges with the test spec
        clientWithOverriddenEndpoint.getSplitChanges(since: 1000, rbSince: 500, till: nil, headers: nil, spec: testSpec) { dataResult in
            do {
                result = try dataResult.unwrap()
                expectation.fulfill()
            } catch let err {
                error = err
                if let httpError = err as? HttpError {
                    outdatedProxyError = httpError
                }
                expectation.fulfill()
            }
        }
        
        // Simulate HTTP 400 response
        requestManager.append(data: Data(), to: 1)
        _ = requestManager.set(responseCode: HttpCode.badRequest, to: 1)
        
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertNil(result)
        XCTAssertNotNil(error)
        XCTAssertNotNil(outdatedProxyError)
        
        // Verify we got our custom error
        if case .outdatedProxyError(let code, let spec)? = outdatedProxyError {
            XCTAssertEqual(code, HttpCode.badRequest)
            XCTAssertEqual(spec, testSpec)
        } else {
            XCTFail("Expected outdatedProxyError error but got \(String(describing: outdatedProxyError))")
        }
    }
    
    func testSplitChangesWithDifferentStatusCode() {
        // Setup with overridden SDK endpoint
        let customEndpoint = "https://custom-sdk.split.io"
        let overriddenServiceEndpoints = ServiceEndpoints.builder().set(sdkEndpoint: customEndpoint).build()
        let overriddenFactory = EndpointFactory(serviceEndpoints: overriddenServiceEndpoints, apiKey: "dummy-api-key", splitsQueryString: "")
        let clientWithOverriddenEndpoint = DefaultRestClient(httpClient: httpClient, endpointFactory: overriddenFactory)
        
        // Specific spec version for this test
        let testSpec = "1.3"
        
        let expectation = XCTestExpectation(description: "API call completes with internal server error")
        var result: TargetingRulesChange?
        var error: Error?
        var httpError: HttpError?

        // Call getSplitChanges with the test spec
        clientWithOverriddenEndpoint.getSplitChanges(since: 1000, rbSince: 500, till: nil, headers: nil, spec: testSpec) { dataResult in
            do {
                result = try dataResult.unwrap()
                expectation.fulfill()
            } catch let err {
                error = err
                if let err = err as? HttpError {
                    httpError = err
                }
                expectation.fulfill()
            }
        }
        
        // Simulate HTTP 500 response (not 400)
        requestManager.append(data: Data(), to: 1)
        _ = requestManager.set(responseCode: HttpCode.internalServerError, to: 1)
        
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertNil(result)
        XCTAssertNotNil(error)
        XCTAssertNotNil(httpError)
        
        // Verify we got the default error for HTTP 500
        if case .unknown(let code, _)? = httpError {
            XCTAssertEqual(code, HttpCode.internalServerError)
        } else {
            XCTFail("Expected HttpError.unknown but got \(String(describing: httpError))")
        }
    }
    
    func testSplitChangesWithDifferentSpec() {
        // Setup with overridden SDK endpoint
        let customEndpoint = "https://custom-sdk.split.io"
        let overriddenServiceEndpoints = ServiceEndpoints.builder().set(sdkEndpoint: customEndpoint).build()
        let overriddenFactory = EndpointFactory(serviceEndpoints: overriddenServiceEndpoints, apiKey: "dummy-api-key", splitsQueryString: "")
        let clientWithOverriddenEndpoint = DefaultRestClient(httpClient: httpClient, endpointFactory: overriddenFactory)
        
        // Different spec version (not 1.3)
        let testSpec = "1.2q"
        
        let expectation = XCTestExpectation(description: "API call completes with client related error")
        var result: TargetingRulesChange?
        var error: Error?
        var httpError: HttpError?

        // Call getSplitChanges with a different spec
        clientWithOverriddenEndpoint.getSplitChanges(since: 1000, rbSince: 500, till: nil, headers: nil, spec: testSpec) { dataResult in
            do {
                result = try dataResult.unwrap()
                expectation.fulfill()
            } catch let err {
                error = err
                if let err = err as? HttpError {
                    httpError = err
                }
                expectation.fulfill()
            }
        }
        
        // Simulate HTTP 400 response
        requestManager.append(data: Data(), to: 1)
        _ = requestManager.set(responseCode: HttpCode.badRequest, to: 1)
        
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertNil(result)
        XCTAssertNotNil(error)
        XCTAssertNotNil(httpError)
        
        // Verify we got the default client related error (not outdatedProxyError)
        if case .clientRelated(let code, _)? = httpError {
            XCTAssertEqual(code, HttpCode.badRequest)
        } else {
            XCTFail("Expected HttpError.clientRelated but got \(String(describing: httpError))")
        }
    }
}
