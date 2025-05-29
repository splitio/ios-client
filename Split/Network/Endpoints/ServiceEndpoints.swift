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

    private(set) public var sdkEndpoint: URL
    private(set) public var eventsEndpoint: URL
    private(set) public var authServiceEndpoint: URL
    private(set) public var streamingServiceEndpoint: URL
    private(set) public var telemetryServiceEndpoint: URL

    private var invalidEndpoints: [String]

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

    var allEndpointsValid: Bool {
        return invalidEndpoints.isEmpty
    }

    var endpointsInvalidMessage: String? {
        var message = ""
        invalidEndpoints.forEach { val in
            message = "".appending("Endpoint is invalid: \(val)\n")
        }

        return message == "" ? nil : message
    }

    private init(
        sdkEndpoint: URL,
        eventsEndpoint: URL,
        authServiceEndpoint: URL,
        streamingServiceEndpoint: URL,
        telemetryServiceEndpoint: URL,
        invalidEndpoints: [String]) {
        self.sdkEndpoint = sdkEndpoint
        self.eventsEndpoint = eventsEndpoint
        self.authServiceEndpoint = authServiceEndpoint
        self.streamingServiceEndpoint = streamingServiceEndpoint
        self.telemetryServiceEndpoint = telemetryServiceEndpoint
        self.invalidEndpoints = invalidEndpoints
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
        /// @param eventsEndpoint: Base URL for events and impressions
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
        /// @param authServiceEndpoint: Base URL for Split API. Should include /api/vx.
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
        /// @param streamingServiceEndpoint: Base URL for streaming service
        /// @return this builder
        ///
        @objc(setStreamingServiceEndpoint:)
        public func set(streamingServiceEndpoint: String) -> Self {
            self.streamingServiceEndpoint = streamingServiceEndpoint
            return self
        }

        /// The rest endpoint that sdk will hit to send telemetry data
        ///
        /// @param telemetryServiceEndpoint: Base URL for telemetry
        /// @return this builder
        ///
        @objc(setTelemetryServiceEndpoint:)
        public func set(telemetryServiceEndpoint: String) -> Self {
            self.telemetryServiceEndpoint = telemetryServiceEndpoint
            return self
        }

        @objc public func build() -> ServiceEndpoints {
            return ServiceEndpoints(
                sdkEndpoint: sdkUrl(),
                eventsEndpoint: eventsUrl(),
                authServiceEndpoint: authServiceUrl(),
                streamingServiceEndpoint: streamingServiceUrl(),
                telemetryServiceEndpoint: telemetryServiceUrl(),
                invalidEndpoints: invalidEndpoints)
        }

        // Using dummy approach and validation array to
        // avoid modifying masive amounts of code
        private var invalidEndpoints = [String]()
        private func sdkUrl() -> URL {
            if let url = createUrl(string: sdkEndpoint) {
                return url
            }
            invalidEndpoints.append(sdkEndpoint)
            return dummyEndpoint()
        }

        private func eventsUrl() -> URL {
            if let url = createUrl(string: eventsEndpoint) {
                return url
            }
            invalidEndpoints.append(eventsEndpoint)
            return dummyEndpoint()
        }

        private func authServiceUrl() -> URL {
            if let url = createUrl(string: authServiceEndpoint) {
                return url
            }
            invalidEndpoints.append(authServiceEndpoint)
            return dummyEndpoint()
        }

        private func streamingServiceUrl() -> URL {
            if let url = createUrl(string: streamingServiceEndpoint) {
                return url
            }
            invalidEndpoints.append(streamingServiceEndpoint)
            return dummyEndpoint()
        }

        private func telemetryServiceUrl() -> URL {
            if let url = createUrl(string: telemetryServiceEndpoint) {
                return url
            }
            invalidEndpoints.append(telemetryServiceEndpoint)
            return dummyEndpoint()
        }

        private func createUrl(string: String) -> URL? {
            #if swift(>=5.9)
                if #available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *) {
                    return URL(string: string, encodingInvalidCharacters: false)
                } else {
                    return URL(string: string)
                }
            #else
                return URL(string: string)
            #endif
        }

        private func dummyEndpoint() -> URL {
            return URL(string: "http://127.0.0.1")!
        }
    }
}
