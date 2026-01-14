//  Created by Martin Cardozo on 13/01/2026

import Foundation

protocol SplitMetadata {}

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
@objc public enum SdkUpdateMetadataType: Int {
    case FLAGS_UPDATE
    case SEGMENTS_UPDATE
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
@objc public class SdkUpdateMetadata: NSObject, SplitMetadata {
    
    @objc public private(set) var type: SdkUpdateMetadataType
    
    /// The names of the entities affected by the update.
    @objc public private(set) var names: [String] = []
    
    @available(*, unavailable)
    override init() {
        fatalError("Use SDK-provided instances only")
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
@objc public class SdkReadyMetadata: NSObject, SplitMetadata {
    
    /// Timestamp (in milliseconds since epoch) of the last successful SDK update.
    ///
    /// A value of `-1` indicates that no update has occurred yet.
    @objc public private(set) var lastUpdateTimestamp: Int64 = -1
    
    /// Indicates whether this SDK initialization corresponds to a fresh install.
    @objc public private(set) var isInitialCacheLoad: Bool = false
    
    @available(*, unavailable)
    override init() {
        fatalError("Use SDK-provided instances only")
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
@objc public class SdkReadyFromCacheMetadata: NSObject, SplitMetadata {
    
    /// Indicates whether this SDK initialization corresponds to a fresh install.
    @objc public private(set) var isInitialCacheLoad: Bool = false
    
    @available(*, unavailable)
    override init() {
        fatalError("Use SDK-provided instances only")
    }
}
