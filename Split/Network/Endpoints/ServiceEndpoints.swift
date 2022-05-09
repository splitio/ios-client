//
// ServiceEndpoints.swift
// Split
//
// Created by Javier L. Avrudsky on 13/05/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

@objc public class ServiceEndpoints: NSObject {

    private static let kSdkEndpoint = "https://sdk.split.io/api"
    static let kEventsEndpoint = "https://events.split.io/api"
    static let kAuthServiceEndpoint = "https://auth.split.io/api/v2"
    static let kStreamingEndpoint = "https://streaming.split.io/sse"
    static let kTelemetryEndpoint = "https://telemetry.split.io/api/v1"

    private (set) var sdkEndpoint: URL
    private (set) var eventsEndpoint: URL
    private (set) var authServiceEndpoint: URL
    private (set) var streamingServiceEndpoint: URL
    private (set) var telemetryServiceEndpoint: URL

    var isCustomSdkEndpoint: Bool {
        return sdkEndpoint.absoluteString != ServiceEndpoints.kSdkEndpoint
    }

    var isCustomEventsEndpoint: Bool {
        return eventsEndpoint.absoluteString != ServiceEndpoints.kEventsEndpoint
    }

    var isCustomAuthServiceEndpoint: Bool {
        return authServiceEndpoint.absoluteString != ServiceEndpoints.kAuthServiceEndpoint
    }

    var isCustomStreamingEndpoint: Bool {
        return streamingServiceEndpoint.absoluteString != ServiceEndpoints.kStreamingEndpoint
    }

    var isCustomTelemetryEndpoint: Bool {
        return telemetryServiceEndpoint.absoluteString != ServiceEndpoints.kTelemetryEndpoint
    }

    private init(sdkEndpoint: URL, eventsEndpoint: URL, authServiceEndpoint: URL,
                 streamingServiceEndpoint: URL, telemetryServiceEndpoint: URL) {
        self.sdkEndpoint = sdkEndpoint
        self.eventsEndpoint = eventsEndpoint
        self.authServiceEndpoint = authServiceEndpoint
        self.streamingServiceEndpoint = streamingServiceEndpoint
        self.telemetryServiceEndpoint = telemetryServiceEndpoint
    }

    @objc public static func builder() -> Builder {
        return Builder()
    }

    @objc(ServiceEndpointsBuilder)
    public class Builder: NSObject {
        private var sdkEndpoint = kSdkEndpoint
        private var eventsEndpoint = kEventsEndpoint
        private var authServiceEndpoint = kAuthServiceEndpoint
        private var streamingServiceEndpoint = kStreamingEndpoint
        private var telemetryServiceEndpoint = kTelemetryEndpoint

        ///
        /// The rest endpoint that sdk will hit for latest features and segments.
        ///
        /// @param Endpoint MUST NOT be null
        /// @return this builder
        ///

        @objc(setSdkEndpoint:)
        public func set(sdkEndpoint: String) -> Self {
            self.sdkEndpoint = sdkEndpoint
            return self
        }

        /// The rest endpoint that sdk will hit to send events and impressions
        ///
        /// @param eventsEndpoint
        /// @return this builder
        ///
        @objc(setEventsEndpoint:)
        public func set(eventsEndpoint: String) -> Self {
            self.eventsEndpoint = eventsEndpoint
            return self
        }

        /// The rest endpoint that sdk will hit to get an SSE authentication token
        /// to subscribe to SSE channels and receive update events
        ///
        /// @param authServiceEndpoint
        /// @return this builder
        ///
        @objc(setAuthServiceEndpoint:)
        public func set(authServiceEndpoint: String) -> Self {
            self.authServiceEndpoint = authServiceEndpoint
            return self
        }

        /// The rest endpoint that sdk will hit to subscribe to SSE channels
        /// and receive update events
        ///
        /// @param streamingServiceEndpoint
        /// @return this builder
        ///
        @objc(setStreamingServiceEndpoint:)
        public func set(streamingServiceEndpoint: String) -> Self {
            self.streamingServiceEndpoint = streamingServiceEndpoint
            return self
        }

        /// The rest endpoint that sdk will hit to send telemetry data
        ///
        /// @param telemetryServiceEndpoint
        /// @return this builder
        ///
        @objc(setTelemetryServiceEndpoint:)
        public func set(telemetryServiceEndpoint: String) -> Self {
            self.telemetryServiceEndpoint = telemetryServiceEndpoint
            return self
        }

        @objc public func build() -> ServiceEndpoints {

            return ServiceEndpoints(sdkEndpoint: sdkUrl(),
                                    eventsEndpoint: eventsUrl(),
                                    authServiceEndpoint: authServiceUrl(),
                                    streamingServiceEndpoint: streamingServiceUrl(),
                                    telemetryServiceEndpoint: telemetryServiceUrl())
        }

        private func sdkUrl() -> URL {
            if let url = URL(string: sdkEndpoint) {
                return url
            }
            Logger.w("SDK URL is not valid, using default")
            return URL(string: ServiceEndpoints.kSdkEndpoint)!
        }

        private func eventsUrl() -> URL {
            if let url = URL(string: eventsEndpoint) {
                return url
            }
            Logger.w("Events URL is not valid, using default")
            return URL(string: ServiceEndpoints.kEventsEndpoint)!
        }

        private func authServiceUrl() -> URL {
            if let url = URL(string: authServiceEndpoint) {
                return url
            }
            Logger.w("Authentication service URL is not valid, using default")
            return URL(string: ServiceEndpoints.kAuthServiceEndpoint)!
        }

        private func streamingServiceUrl() -> URL {

            if let url = URL(string: streamingServiceEndpoint) {
                return url
            }
            Logger.w("Streaming URL is not valid, using default")
            return URL(string: ServiceEndpoints.kStreamingEndpoint)!
        }

        private func telemetryServiceUrl() -> URL {

            if let url = URL(string: telemetryServiceEndpoint) {
                return url
            }
            Logger.w("Telemetry URL is not valid, using default")
            return URL(string: ServiceEndpoints.kTelemetryEndpoint)!
        }
    }
}
