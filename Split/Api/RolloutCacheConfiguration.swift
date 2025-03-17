import Foundation

/// Configuration class for rollout cache. Internal use only.
// @objc public class RolloutCacheConfiguration: NSObject {
internal class RolloutCacheConfiguration: NSObject {
    private(set) var expirationDays: Int
    private(set) var clearOnInit: Bool

    init(expirationDays: Int, clearOnInit: Bool) {
        self.expirationDays = expirationDays
        self.clearOnInit = clearOnInit
    }

    /// Provides a builder for RolloutCacheConfiguration.
    // @objc(builder)
    // public static func builder() -> Builder {
    static func builder() -> Builder {
        return Builder()
    }

    // @objc(RolloutCacheConfigurationBuilder)
    // public class Builder: NSObject {
    class Builder: NSObject {
        private let kMinExpirationDays = 1

        private var expiration = ServiceConstants.defaultRolloutCacheExpiration
        private var clearOnInit = false
        
        // @objc
        // public func build() -> RolloutCacheConfiguration {
        func build() -> RolloutCacheConfiguration {
            return RolloutCacheConfiguration(expirationDays: expiration, clearOnInit: clearOnInit)
        }

        /// Set the expiration time for the rollout definitions cache, in days. Default is 10 days.
        /// - Parameter expirationDays: The expiration time in days.
        /// - Returns: This builder.
        @discardableResult
        // @objc(setExpirationDays:)
        // public func set(expirationDays: Int) -> Builder {
        func set(expirationDays: Int) -> Builder {
            if expirationDays < kMinExpirationDays {
                Logger.w("Cache expiration must be at least 1 day. Using default value.")
                expiration = ServiceConstants.defaultRolloutCacheExpiration
            } else {
                expiration = expirationDays
            }

            return self
        }

        /// Set if the rollout definitions cache should be cleared on initialization. Default is false.
        /// - Parameter clearOnInit: If the cache should be cleared on initialization.
        /// - Returns: This builder.
        @discardableResult
        // @objc(setClearOnInit:)
        // public func set(clearOnInit: Bool) -> Builder {
        func set(clearOnInit: Bool) -> Builder {
            self.clearOnInit = clearOnInit
            return self
        }
    }
}
