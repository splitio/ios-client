//
//  RestClientCustomDecoderTest.swift
//  SplitTests
//
//  Created on 13/05/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import XCTest
@testable import Split

class RestClientCustomDecoderTest: XCTestCase {
    
    private var httpSession: HttpSessionMock!
    private var requestManager: HttpRequestManagerMock!
    private var restClient: DefaultRestClient!
    
    override func setUp() {
        super.setUp()
        httpSession = HttpSessionMock()
        requestManager = HttpRequestManagerMock()
        let serviceEndpoints = ServiceEndpoints.builder()
            .set(sdkEndpoint: "https://sdk.split-test.io")
            .set(eventsEndpoint: "https://events.split-test.io").build()
        let endpointFactory = EndpointFactory(serviceEndpoints: serviceEndpoints, apiKey: "dummy-key", splitsQueryString: "")
        let httpClient = DefaultHttpClient(session: httpSession, requestManager: requestManager)
        restClient = DefaultRestClient(httpClient: httpClient, endpointFactory: endpointFactory)
    }

    override func tearDown() {
        httpSession = nil
        requestManager = nil
        restClient = nil
        super.tearDown()
    }
    
    func testExecuteWithDefaultDecoder() {
        let json = """
        {
            "id": 123,
            "name": "test"
        }
        """
        
        let dummyData = Data(json.utf8)
        let expectation = XCTestExpectation(description: "API call completes")
        var result: TestModel?
        var error: Error?

        restClient.execute(
            endpoint: restClient.endpointFactory.splitChangesEndpoint,
            parameters: nil,
            headers: nil,
            completion: { (dataResult: DataResult<TestModel>) in
                do {
                    result = try dataResult.unwrap()
                    expectation.fulfill()
                } catch let err {
                    error = err
                    expectation.fulfill()
                }
            })

        requestManager.append(data: dummyData, to: 1)
        _ = requestManager.set(responseCode: 200, to: 1)
        
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertNil(error)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, 123)
        XCTAssertEqual(result?.name, "test")
    }
    
    func testExecuteWithCustomDecoder() {
        let json = """
        {
            "custom_id": 456,
            "custom_name": "custom_test"
        }
        """
        
        let dummyData = Data(json.utf8)
        let expectation = XCTestExpectation(description: "API call completes")
        let customDecoderCalled = XCTestExpectation(description: "Custom decoder called")
        var result: TestModel?
        var error: Error?

        let customDecoder: (Data) throws -> TestModel = { data in
            customDecoderCalled.fulfill()
            
            let decoder = JSONDecoder()
            let customModel = try decoder.decode(CustomTestModel.self, from: data)
            // Convert from custom model to standard model
            return TestModel(id: customModel.custom_id, name: customModel.custom_name)
        }

        restClient.execute(
            endpoint: restClient.endpointFactory.splitChangesEndpoint,
            parameters: nil,
            headers: nil,
            customDecoder: customDecoder,
            completion: { (dataResult: DataResult<TestModel>) in
                do {
                    result = try dataResult.unwrap()
                    expectation.fulfill()
                } catch let err {
                    error = err
                    expectation.fulfill()
                }
            })

        requestManager.append(data: dummyData, to: 1)
        _ = requestManager.set(responseCode: 200, to: 1)
        
        wait(for: [expectation, customDecoderCalled], timeout: 1)

        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertNil(error)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, 456)
        XCTAssertEqual(result?.name, "custom_test")
    }
}

private struct CustomTestModel: Decodable {
    let custom_id: Int
    let custom_name: String
}
