//  Created by Martin Cardozo on 13/01/2026

import Foundation

@objc public protocol EventMetadata: Sendable, NSObjectProtocol {}

// MARK: UPDATE
/// Represents the type of SDK update that triggered a metadata callback.
///
/// This enum is used inside `SdkUpdateMetadata` to indicate **what kind of data
/// was updated internally by the SDK**.
///
/// - flagsUpdate:
///   One or more feature flags were updated.
/// - segmentsUpdate:
///   One or more user segments were updated.
///
@objc public enum SdkUpdateMetadataType: Int, Sendable {
    case flagsUpdate
    case segmentsUpdate
}

/// Metadata for SDK update event.
///
/// This object is delivered to update callbacks to provide
/// contextual information about **what changed inside the SDK**.
///
/// It includes:
/// - The type of update that occurred (flags or segments)
/// - The specific flags affected
///
@objcMembers public final class SdkUpdateMetadata: NSObject, EventMetadata, Sendable {
    
    public let type: SdkUpdateMetadataType
    
    /// The names of the entities affected by the update.
    public let names: [String]
    
    @available(*, unavailable)
    public override init() {
        fatalError("Use SDK-provided instances only")
    }
    
    internal init(type: SdkUpdateMetadataType, names: [String]) {
        self.type = type
        self.names = names
        super.init()
    }
}

// MARK: READY
/// Metadata for SDK ready event.
///
/// This object is delivered when the SDK reaches a ready state,
/// providing information about **how and when the data was loaded**.
///
/// It includes:
/// - The timestamp of the last successful update.
/// - Whether the data was loaded from the initial cache.
///
@objcMembers public final class SdkReadyMetadata: NSObject, EventMetadata, Sendable {
    
    /// Timestamp (in milliseconds since epoch) of the last successful SDK update.
    ///
    /// A value of `-1` indicates that no update has occurred yet.
    public let lastUpdateTimestamp: Int64?
    
    /// Indicates whether this SDK initialization corresponds to a fresh install.
    public let isInitialCacheLoad: Bool
    
    @available(*, unavailable)
    public override init() {
        fatalError("Use SDK-provided instances only")
    }
    
    internal init(lastUpdateTimestamp: Int64? = nil, isInitialCacheLoad: Bool) {
        self.isInitialCacheLoad = isInitialCacheLoad
        self.lastUpdateTimestamp = lastUpdateTimestamp
        super.init()
    }
}

// MARK: READY FROM CACHE
/// Metadata for SDK ready-from-cache event.
///
/// This object is delivered when the SDK becomes ready **using cached data**
/// before any successful network update has occurred.
///
/// It indicates that:
/// - The SDK initialized using previously stored data.
/// - No fresh data has been fetched from the network yet.
///
@objcMembers public final class SdkReadyFromCacheMetadata: NSObject, EventMetadata, Sendable {
    
    /// Timestamp (in milliseconds since epoch) of the last successful SDK update.
    ///
    /// A value of `-1` indicates that no update has occurred yet.
    public let lastUpdateTimestamp: Int64?
    
    /// Indicates whether this SDK initialization corresponds to a fresh install.
    public let isInitialCacheLoad: Bool
    
    @available(*, unavailable)
    public override init() {
        fatalError("Use SDK-provided instances only")
    }
    
    internal init(lastUpdateTimestamp: Int64? = nil, isInitialCacheLoad: Bool) {
        self.isInitialCacheLoad = isInitialCacheLoad
        self.lastUpdateTimestamp = lastUpdateTimestamp
        super.init()
    }
}
