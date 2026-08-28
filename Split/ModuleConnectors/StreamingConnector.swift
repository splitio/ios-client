//  Streaming module imports for the Split module

#if SWIFT_PACKAGE || SPLIT_MODULAR

import Streaming

// MARK: - Internal use
typealias EventStreamParser = Streaming.EventStreamParser
typealias SseClient = Streaming.SseClient
typealias DefaultSseClient = Streaming.DefaultSseClient
typealias SseClientConstants = Streaming.SseClientConstants
typealias SseClientFactory = Streaming.SseClientFactory
typealias DefaultSseClientFactory = Streaming.DefaultSseClientFactory
typealias SseConnectionHandler = Streaming.SseConnectionHandler
typealias SseHandler = Streaming.SseHandler
#endif
