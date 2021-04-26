//
//  EndpointFactoryTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 24/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class EndpointFactoryTest: XCTestCase {

    private let kAuthorizationHeader = "Authorization"
    private let kSplitVersionHeader = "SplitSDKVersion"
    private let kContentTypeHeader = "Content-Type"
    private let kAuthorizationBearer = "Bearer \(CommonValues.apiKey)"
    private let kContentTypeJson = "application/json"
    private let kContentTypeEventStream = "text/event-stream"

    var factory: EndpointFactory!
    var serviceEndpoints: ServiceEndpoints!

    override func setUp() {
        serviceEndpoints = ServiceEndpoints.builder().build()
        factory = EndpointFactory(serviceEndpoints: serviceEndpoints,
                                      apiKey: CommonValues.apiKey,
                                      splitsQueryString: "")
    }

    func testMySegmentsEndpoint() {
        let endpointUrl = "\(serviceEndpoints.sdkEndpoint.absoluteString)/mySegments/\(CommonValues.userKey)"
        let endpoint = factory.mySegmentsEndpoint(userKey: CommonValues.userKey)

        XCTAssertEqual(HttpMethod.get, endpoint.method)
        XCTAssertEqual(3, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testSplitChangesEndpoint() {
        let endpointUrl = "\(serviceEndpoints.sdkEndpoint.absoluteString)/splitChanges"
        let endpoint = factory.splitChangesEndpoint

        XCTAssertEqual(HttpMethod.get, endpoint.method)
        XCTAssertEqual(3, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testRecordImpressionsEndpoint() {
        let endpointUrl = "\(serviceEndpoints.eventsEndpoint.absoluteString)/testImpressions/bulk"
        let endpoint = factory.impressionsEndpoint

        XCTAssertEqual(HttpMethod.post, endpoint.method)
        XCTAssertEqual(3, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testRecordEventsEndpoint() {
        let endpointUrl = "\(serviceEndpoints.eventsEndpoint.absoluteString)/events/bulk"
        let endpoint = factory.eventsEndpoint

        XCTAssertEqual(HttpMethod.post, endpoint.method)
        XCTAssertEqual(3, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testTimeMetricsEndpoint() {
        let endpointUrl = "\(serviceEndpoints.eventsEndpoint.absoluteString)/metrics/times"
        let endpoint = factory.timeMetricsEndpoint

        XCTAssertEqual(HttpMethod.post, endpoint.method)
        XCTAssertEqual(3, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testCountMetricsEndpoint() {
        let endpointUrl = "\(serviceEndpoints.eventsEndpoint.absoluteString)/metrics/counters"
        let endpoint = factory.countMetricsEndpoint

        XCTAssertEqual(HttpMethod.post, endpoint.method)
        XCTAssertEqual(3, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testGaugeMetricsEndpoint() {
        let endpointUrl = "\(serviceEndpoints.eventsEndpoint.absoluteString)/metrics/gauge"
        let endpoint = factory.gaugeMetricsEndpoint

        XCTAssertEqual(HttpMethod.post, endpoint.method)
        XCTAssertEqual(3, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testStreamingAuthEndpoint() {
        let endpointUrl = "\(serviceEndpoints.authServiceEndpoint.absoluteString)/auth"
        let endpoint = factory.sseAuthenticationEndpoint

        XCTAssertEqual(HttpMethod.get, endpoint.method)
        XCTAssertEqual(3, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testStreamingEndpoint() {
        let endpointUrl = "\(serviceEndpoints.streamingServiceEndpoint.absoluteString)"
        let endpoint = factory.streamingEndpoint

        XCTAssertEqual(HttpMethod.get, endpoint.method)
        XCTAssertEqual(3, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeEventStream, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    override func tearDown() {
    }
}
