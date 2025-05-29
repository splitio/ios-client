//
//  EndpointFactoryTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 24/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class EndpointFactoryTest: XCTestCase {
    private let kAuthorizationHeader = "Authorization"
    private let kSplitVersionHeader = "SplitSDKVersion"
    private let kContentTypeHeader = "Content-Type"
    private let kAblySplitSdkClientKey = "SplitSDKClientKey"
    private let kAuthorizationBearer = "Bearer \(CommonValues.apiKey)"
    private let kContentTypeJson = "application/json"
    private let kContentTypeEventStream = "text/event-stream"
    private let kAblyClientKey = "2bc3"
    private let commonHeadersCount = 3

    var factory: EndpointFactory!
    var serviceEndpoints: ServiceEndpoints!

    override func setUp() {
        serviceEndpoints = ServiceEndpoints.builder().build()
        factory = EndpointFactory(
            serviceEndpoints: serviceEndpoints,
            apiKey: CommonValues.apiKey,
            splitsQueryString: "")
    }

    func testMySegmentsEndpoint() {
        let endpointUrl = "\(serviceEndpoints.sdkEndpoint.absoluteString)/memberships/\(CommonValues.userKey)"
        let endpoint = factory.mySegmentsEndpoint(userKey: CommonValues.userKey)

        XCTAssertEqual(HttpMethod.get, endpoint.method)
        XCTAssertEqual(commonHeadersCount, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testMySegmentsEndpointSlashKeyEncoding() {
        let userKey = "fake/key"
        let encodedUserKey = userKey.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        let endpointUrl = "\(serviceEndpoints.sdkEndpoint.absoluteString)/memberships/\(encodedUserKey)"
        let endpoint = factory.mySegmentsEndpoint(userKey: userKey)

        XCTAssertEqual(HttpMethod.get, endpoint.method)
        XCTAssertEqual(commonHeadersCount, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testSplitChangesEndpoint() {
        let endpointUrl = "\(serviceEndpoints.sdkEndpoint.absoluteString)/splitChanges"
        let endpoint = factory.splitChangesEndpoint

        XCTAssertEqual(HttpMethod.get, endpoint.method)
        XCTAssertEqual(commonHeadersCount, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testRecordImpressionsEndpoint() {
        let endpointUrl = "\(serviceEndpoints.eventsEndpoint.absoluteString)/testImpressions/bulk"
        let endpoint = factory.impressionsEndpoint

        XCTAssertEqual(HttpMethod.post, endpoint.method)
        XCTAssertEqual(commonHeadersCount, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testRecordEventsEndpoint() {
        let endpointUrl = "\(serviceEndpoints.eventsEndpoint.absoluteString)/events/bulk"
        let endpoint = factory.eventsEndpoint

        XCTAssertEqual(HttpMethod.post, endpoint.method)
        XCTAssertEqual(commonHeadersCount, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testTelemetryConfigEndpoint() {
        let endpointUrl = "\(serviceEndpoints.telemetryServiceEndpoint.absoluteString)/metrics/config"
        let endpoint = factory.telemetryConfigEndpoint

        XCTAssertEqual(HttpMethod.post, endpoint.method)
        XCTAssertEqual(commonHeadersCount, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testTelemetryUsageEndpoint() {
        let endpointUrl = "\(serviceEndpoints.telemetryServiceEndpoint.absoluteString)/metrics/usage"
        let endpoint = factory.telemetryUsageEndpoint

        XCTAssertEqual(HttpMethod.post, endpoint.method)
        XCTAssertEqual(commonHeadersCount, endpoint.headers.count)
        XCTAssertEqual(kAuthorizationBearer, endpoint.headers[kAuthorizationHeader])
        XCTAssertEqual(kContentTypeJson, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    func testStreamingAuthEndpoint() {
        let endpointUrl = "\(serviceEndpoints.authServiceEndpoint.absoluteString)/auth"
        let endpoint = factory.sseAuthenticationEndpoint

        XCTAssertEqual(HttpMethod.get, endpoint.method)
        XCTAssertEqual(commonHeadersCount, endpoint.headers.count)
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
        XCTAssertEqual(kContentTypeEventStream, endpoint.headers[kContentTypeHeader])
        XCTAssertEqual(Version.sdk, endpoint.headers[kSplitVersionHeader])
        XCTAssertEqual(kAblyClientKey, endpoint.headers[kAblySplitSdkClientKey])
        XCTAssertEqual(endpointUrl, endpoint.url.absoluteString)
    }

    override func tearDown() {}
}
