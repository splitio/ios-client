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
    private static let kAblySplitSdkClientKey = "SplitSDKClientKey"
    private static let kAblySplitSdkClientKeyLength = 4
    private struct EndpointsPath {
        static let sseAuth = "auth"
        static let splitChanges = "splitChanges"
        static let mySegments = "mySegments"
        static let impressions = "testImpressions/bulk"
        static let impressionsCount = "testImpressions/count"
        static let events = "events/bulk"
        static let telemetryConfig = "metrics/config"
        static let telemetryUsage = "metrics/usage"
        static let uniqueKeys = "keys/cs"
    }

    let serviceEndpoints: ServiceEndpoints
    let splitChangesEndpoint: Endpoint
    let impressionsEndpoint: Endpoint
    let impressionsCountEndpoint: Endpoint
    let eventsEndpoint: Endpoint
    let telemetryConfigEndpoint: Endpoint
    let telemetryUsageEndpoint: Endpoint
    let sseAuthenticationEndpoint: Endpoint
    let streamingEndpoint: Endpoint
    let uniqueKeysEndpoint: Endpoint
    let apiKey: String

    init(serviceEndpoints: ServiceEndpoints, apiKey: String, splitsQueryString: String) {
        self.apiKey = apiKey
        self.serviceEndpoints = serviceEndpoints

        let commondHeaders = Self.basicHeaders(apiKey: apiKey)
        let typeHeader = Self.typeHeader()

        splitChangesEndpoint = Endpoint
            .builder(baseUrl: serviceEndpoints.sdkEndpoint, path: EndpointsPath.splitChanges,
                     defaultQueryString: splitsQueryString)
            .add(headers: commondHeaders).add(headers: typeHeader).build()

        impressionsEndpoint = Endpoint
                .builder(baseUrl: serviceEndpoints.eventsEndpoint, path: EndpointsPath.impressions)
                .set(method: .post).add(headers: commondHeaders).add(headers: typeHeader).build()

        impressionsCountEndpoint = Endpoint
                .builder(baseUrl: serviceEndpoints.eventsEndpoint, path: EndpointsPath.impressionsCount)
                .set(method: .post).add(headers: commondHeaders).add(headers: typeHeader).build()

        eventsEndpoint = Endpoint
                .builder(baseUrl: serviceEndpoints.eventsEndpoint, path: EndpointsPath.events)
                .set(method: .post).add(headers: commondHeaders).add(headers: typeHeader).build()

        telemetryConfigEndpoint = Endpoint
                .builder(baseUrl: serviceEndpoints.telemetryServiceEndpoint, path: EndpointsPath.telemetryConfig)
                .set(method: .post).add(headers: commondHeaders).add(headers: typeHeader).build()

        telemetryUsageEndpoint = Endpoint
                .builder(baseUrl: serviceEndpoints.telemetryServiceEndpoint, path: EndpointsPath.telemetryUsage)
                .set(method: .post).add(headers: commondHeaders).add(headers: typeHeader).build()

        sseAuthenticationEndpoint = Endpoint
            .builder(baseUrl: serviceEndpoints.authServiceEndpoint, path: EndpointsPath.sseAuth)
                .set(method: .get).add(headers: commondHeaders).add(headers: typeHeader).build()

        streamingEndpoint = Endpoint
                .builder(baseUrl: serviceEndpoints.streamingServiceEndpoint)
                .set(method: .get).add(headers: Self.streamingHeaders(apiKey: apiKey)).build()

        uniqueKeysEndpoint = Endpoint
                .builder(baseUrl: serviceEndpoints.telemetryServiceEndpoint, path: EndpointsPath.uniqueKeys)
                .set(method: .post).add(headers: commondHeaders).add(headers: typeHeader).build()
    }

    func mySegmentsEndpoint(userKey: String) -> Endpoint {
        let commonHeaders = Self.basicHeaders(apiKey: self.apiKey)
        let typeHeader = Self.typeHeader()
        let encodedUserKey = userKey.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? userKey
        return Endpoint
            .builder(baseUrl: serviceEndpoints.sdkEndpoint,
                     encodedPath: "\(EndpointsPath.mySegments)/\(encodedUserKey)")
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

    private static func streamingHeaders(apiKey: String) -> [String: String] {
        return [
            Self.kContentTypeHeader: Self.kContentTypeEventStream,
            Self.kAblySplitSdkClientKey: String(apiKey.suffix(kAblySplitSdkClientKeyLength)),
            Self.kSplitVersionHeader: Version.sdk
        ]

    }
}
