//
//  TelemetryStats.swift
//  Split
//
//  Created by Javier Avrudsky on 01-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

struct TelemetryHttpLatencies: Codable {

    var splits: [Int]?
    var mySegments: [Int]?
    var impressions: [Int]?
    var impressionsCount: [Int]?
    var events: [Int]?
    var token: [Int]?
    var telemetry: [Int]?

    enum CodingKeys: String, CodingKey {
        case splits = "sp"
        case mySegments = "ms"
        case impressions = "im"
        case impressionsCount = "ic"
        case events = "ev"
        case token = "to"
        case telemetry = "te"
    }
}

enum TelemetryStreamingEventType: Int {
    case connectionStablished = 0
    case occupancyPri = 10
    case occupancySec = 20
    case streamingStatus = 30
    case connectionError = 40
    case tokenRefresh = 50
    case ablyError = 60
    case syncModeUpdate = 70
}

struct TelemetryStreamingEventValue {
    static let empty: Int64 = 0

    // Streaming event
    static let streamingDisabled: Int64 = 0
    static let streamingEnabled: Int64 = 1
    static let streamingPaused: Int64 = 2

    // SSE connection error
    static let sseConnErrorRequested: Int64 = 0
    static let sseConnErrorNonRequested: Int64 = 1

    // Sync Mode Update
    static let syncModeStreaming: Int64 = 0
    static let syncModePolling: Int64 = 1
}

struct TelemetryStreamingEvent: Codable {
    var type: Int
    var data: Int64?
    var timestamp: Int64

    enum CodingKeys: String, CodingKey {
        case type = "e"
        case data = "d"
        case timestamp = "t"
    }
}

struct TelemetryHttpErrors: Codable {

    var splits: [Int: Int]?
    var mySegments: [Int: Int]?
    var impressions: [Int: Int]?
    var impressionsCount: [Int: Int]?
    var events: [Int: Int]?
    var token: [Int: Int]?
    var telemetry: [Int: Int]?

    enum CodingKeys: String, CodingKey {
        case splits = "sp"
        case mySegments = "ms"
        case impressions = "im"
        case impressionsCount = "ic"
        case events = "ev"
        case token = "to"
        case telemetry = "te"
    }
}

struct TelemetryMethodExceptions: Codable {
    var treatment: Int?
    var treatments: Int?
    var treatmentWithConfig: Int?
    var treatmentsWithConfig: Int?
    var track: Int?

    enum CodingKeys: String, CodingKey {
        case treatment = "t"
        case treatments = "ts"
        case treatmentWithConfig = "tc"
        case treatmentsWithConfig = "tcs"
        case track = "tr"
    }
}

struct TelemetryLastSync: Codable {

    var splits: Int64?
    var impressions: Int64?
    var impressionsCount: Int64?
    var events: Int64?
    var token: Int64?
    var telemetry: Int64?
    var mySegments: Int64?

    enum CodingKeys: String, CodingKey {
        case splits = "sp"
        case impressions = "im"
        case impressionsCount = "ic"
        case events = "ev"
        case token = "to"
        case telemetry = "te"
        case mySegments = "ms"
    }
}

struct TelemetryMethodLatencies: Codable {

    var treatment: [Int]?
    var treatments: [Int]?
    var treatmentWithConfig: [Int]?
    var treatmentsWithConfig: [Int]?
    var track: [Int]?

    enum CodingKeys: String, CodingKey {
        case treatment = "t"
        case treatments = "ts"
        case treatmentWithConfig = "tc"
        case treatmentsWithConfig = "tcs"
        case track = "tr"
    }
}

// Codable to allow testing
struct TelemetryStats: Codable {

    var lastSynchronization: TelemetryLastSync?
    var methodLatencies: TelemetryMethodLatencies?
    var methodExceptions: TelemetryMethodExceptions?
    var httpErrors: TelemetryHttpErrors?
    var httpLatencies: TelemetryHttpLatencies?
    var tokenRefreshes: Int?
    var authRejections: Int?
    var impressionsQueued: Int?
    var impressionsDeduped: Int?
    var impressionsDropped: Int?
    var splitCount: Int?
    var segmentCount: Int?
    var segmentKeyCount: Int?
    var sessionLengthMs: Int64?
    var eventsQueued: Int?
    var eventsDropped: Int?
    var streamingEvents: [TelemetryStreamingEvent]?
    var tags: [String]?

    enum CodingKeys: String, CodingKey {
        case lastSynchronization = "lS"
        case methodLatencies = "ml"
        case methodExceptions = "mE"
        case httpErrors = "hE"
        case httpLatencies = "hL"
        case tokenRefreshes = "tR"
        case authRejections = "aR"
        case impressionsQueued = "iQ"
        case impressionsDeduped = "iDe"
        case impressionsDropped = "iDr"
        case splitCount = "spC"
        case segmentCount = "seC"
        case segmentKeyCount = "skC"
        case sessionLengthMs = "sL"
        case eventsQueued = "eQ"
        case eventsDropped = "eD"
        case streamingEvents = "sE"
        case tags = "t"
    }
}
