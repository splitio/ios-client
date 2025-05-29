//
//  ServiceEndpointsTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10/01/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class ServiceEndpointsTests: XCTestCase {
    override func setUp() {}

    func testBuilderValidationOk() {
        let se = ServiceEndpoints.builder()
            .set(authServiceEndpoint: "http://www.gmail.com")
            .set(sdkEndpoint: "http://www.gmail.com")
            .set(eventsEndpoint: "http://www.gmail.com")
            .set(authServiceEndpoint: "http://www.gmail.com")
            .set(telemetryServiceEndpoint: "http://www.gmail.com")
            .build()

        XCTAssertTrue(se.allEndpointsValid)
    }

    func testBuilderValidationAuthError() {
        let se = ServiceEndpoints.builder()
            .set(authServiceEndpoint: "wrong url auth")
            .build()

        XCTAssertFalse(se.allEndpointsValid)
        XCTAssertEqual("Endpoint is invalid: wrong url auth\n", se.endpointsInvalidMessage)
    }

    func testBuilderValidationSdkError() {
        let se = ServiceEndpoints.builder()
            .set(sdkEndpoint: "wrong url sdk")
            .build()

        XCTAssertFalse(se.allEndpointsValid)
        XCTAssertEqual("Endpoint is invalid: wrong url sdk\n", se.endpointsInvalidMessage)
    }

    func testBuilderValidationEventsError() {
        let se = ServiceEndpoints.builder()
            .set(eventsEndpoint: "wrong url events")
            .build()

        XCTAssertFalse(se.allEndpointsValid)
        XCTAssertEqual("Endpoint is invalid: wrong url events\n", se.endpointsInvalidMessage)
    }

    func testBuilderValidationTelemetryError() {
        let se = ServiceEndpoints.builder()
            .set(eventsEndpoint: "wrong url telemetry")
            .build()

        XCTAssertFalse(se.allEndpointsValid)
        XCTAssertEqual("Endpoint is invalid: wrong url telemetry\n", se.endpointsInvalidMessage)
    }

    func testBuilderValidationStreamingError() {
        let se = ServiceEndpoints.builder()
            .set(eventsEndpoint: "wrong url streaming")
            .build()

        XCTAssertFalse(se.allEndpointsValid)
        XCTAssertEqual("Endpoint is invalid: wrong url streaming\n", se.endpointsInvalidMessage)
    }

    override func tearDown() {}
}
