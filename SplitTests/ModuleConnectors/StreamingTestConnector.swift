// StreamingTestConnector.swift

#if SWIFT_PACKAGE || SPLIT_MODULAR
import SplitStreaming

// MARK: - Streaming types for testing
typealias EventStreamParser = SplitStreaming.EventStreamParser
typealias SseClient = SplitStreaming.SseClient
typealias DefaultSseClient = SplitStreaming.DefaultSseClient
typealias SseClientConstants = SplitStreaming.SseClientConstants
typealias SseClientFactory = SplitStreaming.SseClientFactory
typealias DefaultSseClientFactory = SplitStreaming.DefaultSseClientFactory
typealias SseConnectionHandler = SplitStreaming.SseConnectionHandler
typealias SseHandler = SplitStreaming.SseHandler
#endif
