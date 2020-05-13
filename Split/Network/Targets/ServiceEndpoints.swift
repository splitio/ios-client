//
// ServiceEndpoints.swift
// Split
//
// Created by Javier L. Avrudsky on 13/05/2020.
// Copyright (c) 2020 Split. All rights reserved.
//

import Foundation

class ServiceEndpoints {

    private static let kSdkEndpoint = "https://sdk.split.io/api"
    private static let kEventsEndpoint = "https://events.split.io/api"
    private static let kAuthServiceEndpoint = "https://auth.split.io/api"
    private static let kStreamingEndpoint = "https://split-realtime.ably.io/sse"

    private (set) var sdkEndpoint: URL
    private (set) var eventsEndpoint: URL
    private (set) var authServiceEndpoint: URL
    private (set) var streamingServiceEndpoint: URL

    init(sdkEndpoint: URL, eventsEndpoint: URL, authServiceEndpoint: URL, streamingServiceEndpoint: URL) {
        self.sdkEndpoint = sdkEndpoint
        self.eventsEndpoint = eventsEndpoint
        self.authServiceEndpoint = authServiceEndpoint
        self.streamingServiceEndpoint = streamingServiceEndpoint
    }

    class Builder {
        private var sdkEndpoint = kSdkEndpoint
        private var eventsEndpoint = kEventsEndpoint
        private var authServiceEndpoint = kAuthServiceEndpoint
        private var streamingServiceEndpoint = kStreamingEndpoint

        init() {
        }

        ///
        /// The rest endpoint that sdk will hit for latest features and segments.
        ///
        /// @param Endpoint MUST NOT be null
        /// @return this builder
        ///
        func set(sdkEndpoint: String) -> Self {
            self.sdkEndpoint = sdkEndpoint
            return self
        }

        /// The rest endpoint that sdk will hit to send events and impressions
        ///
        /// @param eventsEndpoint
        /// @return this builder
        ///
        func set(eventsEndpoint: String) -> Self {
            self.eventsEndpoint = eventsEndpoint
            return self
        }

        /// The rest endpoint that sdk will hit to get an SSE authentication token
        /// to subscribe to SSE channels and receive update events
        ///
        /// @param authServiceEndpoint
        /// @return this builder
        ///
        func set(authServiceEndpoint: String) -> Self {
            self.authServiceEndpoint = authServiceEndpoint
            return self
        }

        /// The rest endpoint that sdk will hit to subscribe to SSE channels
        /// and receive update events
        ///
        /// @param streamingServiceEndpoint
        /// @return this builder
        ///
        func set(streamingServiceEndpoint: String) -> Self {
            self.streamingServiceEndpoint = streamingServiceEndpoint
            return self
        }

        func build() -> ServiceEndpoints {
            guard let sdkUrl = URL(string: sdkEndpoint) else {
                preconditionFailure("SDK URL is not valid")
            }

            guard let eventsUrl = URL(string: eventsEndpoint) else {
                preconditionFailure("Events URL is not valid")
            }

            guard let authServiceUrl = URL(string: authServiceEndpoint) else {
                preconditionFailure("Authentication service URL is not valid")
            }

            guard let streamingServiceUrl = URL(string: streamingServiceEndpoint) else {
                preconditionFailure("Streaming URL is not valid")
            }
            return ServiceEndpoints(
                    sdkEndpoint: sdkUrl,
                    eventsEndpoint: eventsUrl,
                    authServiceEndpoint: authServiceUrl,
                    streamingServiceEndpoint: streamingServiceUrl)
        }
    }
}
