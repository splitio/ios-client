//
// EndpointFactory.swift
// Split
//
// Created by Javier L. Avrudsky on 13/05/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

class EndpointFactory {
    private static let kAuthorizationHeader = "Authorization"
    private static let kSplitVersionHeader = "SplitSDKVersion"
    private static let kContentTypeHeader = "Content-Type"
    private static let kAuthorizationBearer = "Bearer"
    private static let kContentTypeJson = "application/json"
    private static let kContentTypeEventStream = "text/event-stream"
    private struct EndpointsPath {
        static let sseAuth = "auth"
        static let splitChanges = "splitChanges"
        static let mySegments = "mySegments"
        static let impressions = "testImpressions/bulk"
        static let events = "events/bulk"
        static let timeMetrics = "metrics/times"
        static let counterMetrics = "metrics/counters"
        static let gaugeMetrics = "metrics/gauge"
    }

    let serviceEndpoints: ServiceEndpoints
    let splitChangesEndpoint: Endpoint
    let impressionsEndpoint: Endpoint
    let eventsEndpoint: Endpoint
    let timeMetricsEndpoint: Endpoint
    let countMetricsEndpoint: Endpoint
    let gaugeMetricsEndpoint: Endpoint
    let sseAuthenticationEndpoint: Endpoint
    let streamingEndpoint: Endpoint
    let apiKey: String

    init(serviceEndpoints: ServiceEndpoints, apiKey: String, splitsQueryString: String) {
        self.apiKey = apiKey
        self.serviceEndpoints = serviceEndpoints

        let commondHeaders = Self.basicHeaders(apiKey: apiKey)
        let typeHeader = Self.typeHeader()
        let streamEventHeader = [Self.kContentTypeHeader: Self.kContentTypeEventStream]

        splitChangesEndpoint = Endpoint
            .builder(baseUrl: serviceEndpoints.sdkEndpoint, path: EndpointsPath.splitChanges,
                     defaultQueryString: splitsQueryString)
            .add(headers: commondHeaders).add(headers: typeHeader).build()

        impressionsEndpoint = Endpoint
                .builder(baseUrl: serviceEndpoints.eventsEndpoint, path: EndpointsPath.impressions)
                .set(method: .post).add(headers: commondHeaders).add(headers: typeHeader).build()

        eventsEndpoint = Endpoint
                .builder(baseUrl: serviceEndpoints.eventsEndpoint, path: EndpointsPath.events)
                .set(method: .post).add(headers: commondHeaders).add(headers: typeHeader).build()

        timeMetricsEndpoint = Endpoint
                .builder(baseUrl: serviceEndpoints.eventsEndpoint, path: EndpointsPath.timeMetrics)
                .set(method: .post).add(headers: commondHeaders).add(headers: typeHeader).build()

        countMetricsEndpoint = Endpoint
                .builder(baseUrl: serviceEndpoints.eventsEndpoint, path: EndpointsPath.counterMetrics)
                .set(method: .post).add(headers: commondHeaders).add(headers: typeHeader).build()

        gaugeMetricsEndpoint = Endpoint
                .builder(baseUrl: serviceEndpoints.eventsEndpoint, path: EndpointsPath.gaugeMetrics)
                .set(method: .post).add(headers: commondHeaders).add(headers: typeHeader).build()

        sseAuthenticationEndpoint = Endpoint
            .builder(baseUrl: serviceEndpoints.authServiceEndpoint, path: EndpointsPath.sseAuth)
                .set(method: .get).add(headers: commondHeaders).add(headers: typeHeader).build()

        streamingEndpoint = Endpoint
                .builder(baseUrl: serviceEndpoints.streamingServiceEndpoint)
                .set(method: .get).add(headers: commondHeaders).add(headers: streamEventHeader).build()
    }

    func mySegmentsEndpoint(userKey: String) -> Endpoint {
        let commonHeaders = Self.basicHeaders(apiKey: self.apiKey)
        let typeHeader = Self.typeHeader()
        return Endpoint
            .builder(baseUrl: serviceEndpoints.sdkEndpoint, path: "\(EndpointsPath.mySegments)/\(userKey)")
            .add(headers: commonHeaders).add(headers: typeHeader).build()
    }

    private static func basicHeaders(apiKey: String) -> [String: String] {
        return [
            Self.kAuthorizationHeader: "\(Self.kAuthorizationBearer) \(apiKey)",
            Self.kSplitVersionHeader: Version.sdk
        ]
    }

    private static func typeHeader() -> [String: String] {
        return [Self.kContentTypeHeader: Self.kContentTypeJson]
    }
}
