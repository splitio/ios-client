//
//  TelemetryConfig.swift
//  Split
//
//  Created by Javier Avrudsky on 01-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

struct TelemetryRates: Codable {
    var splits: Int
    var mySegments: Int
    var impressions: Int
    var events: Int
    var telemetry: Int

    enum CodingKeys: String, CodingKey {
        case splits = "sp"
        case mySegments = "se"
        case impressions = "im"
        case events = "ev"
        case telemetry = "te"
    }
}

struct TelemetryUrlOverrides: Codable {
    var sdk: Bool
    var events: Bool
    var auth: Bool
    var stream: Bool
    var telemetry: Bool

    enum CodingKeys: String, CodingKey {
        case sdk = "s"
        case events = "e"
        case auth = "a"
        case stream = "st"
        case telemetry = "t"
    }
}

struct TelemetryConfig: Codable {
    let operationMode = 0 // 0: Standalone, 1: Consumer
    let storage: String = "memory"
    var streamingEnabled: Bool
    var rates: TelemetryRates?
    var urlOverrides: TelemetryUrlOverrides?
    var impressionsQueueSize: Int
    var eventsQueueSize: Int64
    var impressionsMode: Int
    var impressionsListenerEnabled: Bool
    var httpProxyDetected: Bool
    var activeFactories: Int
    var redundantFactories: Int?
    var timeUntilReady: Int64
    var timeUntilReadyFromCache: Int64
    var nonReadyUsages: Int
    var integrations: [String]?
    var tags: [String]?

    enum CodingKeys: String, CodingKey {
        case operationMode = "oM"
        case streamingEnabled = "sE"
        case storage = "st"
        case rates = "rR"
        case urlOverrides = "uO"
        case impressionsQueueSize = "iQ"
        case eventsQueueSize = "eQ"
        case impressionsMode = "iM"
        case impressionsListenerEnabled = "iL"
        case httpProxyDetected = "hP"
        case activeFactories = "aF"
        case redundantFactories = "rF"
        case timeUntilReady = "tR"
        case timeUntilReadyFromCache = "tC"
        case nonReadyUsages = "nR"
        case integrations = "i"
        case tags = "t"
    }
}
