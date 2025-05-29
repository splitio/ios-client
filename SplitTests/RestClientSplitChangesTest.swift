//
//  RestClientSplitChangesTest.swift
//  SplitTests
//
//  Created on 12/05/2025.
//  Copyright © 2025 Split. All rights reserved.
//

@testable import Split
import XCTest

class RestClientSplitChangesTest: XCTestCase {
    var httpClient: HttpClient!
    var httpSession: HttpSessionMock!
    var requestManager: HttpRequestManagerMock!
    var factory: EndpointFactory!
    var serviceEndpoints: ServiceEndpoints!
    var restClient: DefaultRestClient!

    override func setUp() {
        httpSession = HttpSessionMock()
        requestManager = HttpRequestManagerMock()
        httpClient = DefaultHttpClient(session: httpSession, requestManager: requestManager)
        serviceEndpoints = ServiceEndpoints.builder().build()
        factory = EndpointFactory(serviceEndpoints: serviceEndpoints, apiKey: "dummy-api-key", splitsQueryString: "")
        restClient = DefaultRestClient(httpClient: httpClient, endpointFactory: factory)
    }

    func testGetSplitChangesWithTargetingRulesFormat() {
        let json = """
        {"ff": {"d":[{"name": "test_split", "trafficTypeName": "user", "status": "active"}], "s": 1000, "t": 1001}, 
         "rbs": {"d":[{"name": "test_segment", "trafficTypeName": "user", "changeNumber": 1000, "status": "active"}], "s": 500, "t": 501}}
        """

        let dummyData = Data(json.utf8)
        let expectation = XCTestExpectation(description: "API call completes")
        var result: TargetingRulesChange?
        var error: Error?

        restClient.getSplitChanges(since: 1000, rbSince: 500, till: nil, headers: nil) { dataResult in
            do {
                result = try dataResult.unwrap()
                expectation.fulfill()
            } catch let err {
                error = err
                expectation.fulfill()
            }
        }

        requestManager.append(data: dummyData, to: 1)
        _ = requestManager.set(responseCode: 200, to: 1)

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertNil(error)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.featureFlags.since, 1000)
        XCTAssertEqual(result?.featureFlags.till, 1001)
        XCTAssertEqual(result?.featureFlags.splits.count, 1)
        XCTAssertEqual(result?.featureFlags.splits[0].name, "test_split")

        XCTAssertEqual(result?.ruleBasedSegments.since, 500)
        XCTAssertEqual(result?.ruleBasedSegments.till, 501)
        XCTAssertEqual(result?.ruleBasedSegments.segments.count, 1)
        XCTAssertEqual(result?.ruleBasedSegments.segments[0].name, "test_segment")
        XCTAssertTrue(requestManager.request.url.absoluteString.contains("rbSince=500"))
    }

    func testGetSplitChangesWithLegacyFullKeyFormat() {
        let json = """
        {
              "splits": [
                {
                  "trafficTypeName": "account",
                  "name": "test_split",
                  "trafficAllocation": 59,
                  "trafficAllocationSeed": -2108186082,
                  "seed": -1947050785,
                  "status": "ACTIVE",
                  "killed": false,
                  "defaultTreatment": "off",
                  "changeNumber": 1506703262916,
                  "algo": 2,
                  "conditions": [
                    {
                      "conditionType": "WHITELIST",
                      "matcherGroup": {
                        "combiner": "AND",
                        "matchers": [
                          {
                            "keySelector": null,
                            "matcherType": "WHITELIST",
                            "negate": false,
                            "userDefinedSegmentMatcherData": null,
                            "whitelistMatcherData": {
                              "whitelist": [
                                "nico_test",
                                "othertest"
                              ]
                            },
                            "unaryNumericMatcherData": null,
                            "betweenMatcherData": null,
                            "booleanMatcherData": null,
                            "dependencyMatcherData": null,
                            "stringMatcherData": null
                          }
                        ]
                      },
                      "partitions": [
                        {
                          "treatment": "on",
                          "size": 100
                        }
                      ],
                      "label": "whitelisted"
                    },
                    {
                      "conditionType": "WHITELIST",
                      "matcherGroup": {
                        "combiner": "AND",
                        "matchers": [
                          {
                            "keySelector": null,
                            "matcherType": "WHITELIST",
                            "negate": false,
                            "userDefinedSegmentMatcherData": null,
                            "whitelistMatcherData": {
                              "whitelist": [
                                "bla"
                              ]
                            },
                            "unaryNumericMatcherData": null,
                            "betweenMatcherData": null,
                            "booleanMatcherData": null,
                            "dependencyMatcherData": null,
                            "stringMatcherData": null
                          }
                        ]
                      },
                      "partitions": [
                        {
                          "treatment": "off",
                          "size": 100
                        }
                      ],
                      "label": "whitelisted"
                    },
                    {
                      "conditionType": "ROLLOUT",
                      "matcherGroup": {
                        "combiner": "AND",
                        "matchers": [
                          {
                            "keySelector": {
                              "trafficType": "account",
                              "attribute": null
                            },
                            "matcherType": "ALL_KEYS",
                            "negate": false,
                            "userDefinedSegmentMatcherData": null,
                            "whitelistMatcherData": null,
                            "unaryNumericMatcherData": null,
                            "betweenMatcherData": null,
                            "booleanMatcherData": null,
                            "dependencyMatcherData": null,
                            "stringMatcherData": null
                          }
                        ]
                      },
                      "partitions": [
                        {
                          "treatment": "on",
                          "size": 0
                        },
                        {
                          "treatment": "off",
                          "size": 100
                        },
                        {
                          "treatment": "visa",
                          "size": 0
                        }
                      ],
                      "label": "in segment all"
                    }
                  ]
                }
              ],
              "since": 1000,
              "till": 1001
            }
        """

        let dummyData = Data(json.utf8)
        let expectation = XCTestExpectation(description: "API call completes")
        var result: TargetingRulesChange?
        var error: Error?

        restClient.getSplitChanges(since: 1000, rbSince: 500, till: nil, headers: nil) { dataResult in
            do {
                result = try dataResult.unwrap()
                expectation.fulfill()
            } catch let err {
                error = err
                expectation.fulfill()
            }
        }

        // Simulate response
        requestManager.append(data: dummyData, to: 1)
        _ = requestManager.set(responseCode: 200, to: 1)

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertNil(error)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.featureFlags.since, 1000)
        XCTAssertEqual(result?.featureFlags.till, 1001)
        XCTAssertEqual(result?.featureFlags.splits.count, 1)
        XCTAssertEqual(result?.featureFlags.splits[0].name, "test_split")

        XCTAssertEqual(result?.ruleBasedSegments.since, -1)
        XCTAssertEqual(result?.ruleBasedSegments.till, -1)
        XCTAssertEqual(result?.ruleBasedSegments.segments.count, 0)

        XCTAssertTrue(requestManager.request.url.absoluteString.contains("rbSince=500"))
    }

    func testGetSplitChangesWithError() {
        let expectation = XCTestExpectation(description: "API call completes with error")
        var result: TargetingRulesChange?
        var error: Error?

        restClient.getSplitChanges(since: 1000, rbSince: 500, till: nil, headers: nil) { dataResult in
            do {
                result = try dataResult.unwrap()
                expectation.fulfill()
            } catch let err {
                error = err
                expectation.fulfill()
            }
        }

        let mockError = HttpError.unknown(code: 500, message: "Test error")
        requestManager.complete(taskIdentifier: 1, error: mockError)

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertNil(result)
        XCTAssertNotNil(error)
        XCTAssertEqual(500, (error as? HttpError)?.code)
    }

    func testCustomErrorHandlerForDirectHttpErrors() {
        let overriddenServiceEndpoints = ServiceEndpoints.builder()
            .set(sdkEndpoint: "https://custom-proxy.io/api")
            .build()
        let overriddenFactory = EndpointFactory(
            serviceEndpoints: overriddenServiceEndpoints,
            apiKey: "dummy-api-key",
            splitsQueryString: "")
        let clientWithOverriddenEndpoint = DefaultRestClient(httpClient: httpClient, endpointFactory: overriddenFactory)

        let expectation = XCTestExpectation(description: "API call completes with custom-handled error")
        var result: TargetingRulesChange?
        var error: Error?

        clientWithOverriddenEndpoint
            .getSplitChanges(since: 1000, rbSince: 500, till: nil, headers: nil, spec: "1.3") { dataResult in
                do {
                    result = try dataResult.unwrap()
                    expectation.fulfill()
                } catch let err {
                    error = err
                    expectation.fulfill()
                }
            }

        let clientRelatedError = HttpError.clientRelated(code: 400, internalCode: -1)
        requestManager.complete(taskIdentifier: 1, error: clientRelatedError)

        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(1, httpSession.dataTaskCallCount)
        XCTAssertEqual(1, requestManager.addRequestCallCount)
        XCTAssertNil(result)
        XCTAssertNotNil(error)

        // Verify the error was processed by the custom error handler and converted to outdatedProxyError
        if let httpError = error as? HttpError {
            switch httpError {
            case let .outdatedProxyError(code, spec):
                XCTAssertEqual(400, code)
                XCTAssertEqual("1.3", spec)
            default:
                XCTFail("Expected outdatedProxyError but got \(httpError)")
            }
        } else {
            XCTFail("Expected HttpError but got \(String(describing: error))")
        }
    }
}
