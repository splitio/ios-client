//
//  SplitConfig.swift
//  Split
//
//  Created by Brian Sztamfater on 21/9/17.
//
//

import Foundation

public typealias SplitImpressionListener = (SplitImpression) -> Void

public class SplitClientConfig: NSObject {

    ///
    /// How many milliseconds to wait before triggering a timeout event when the SDK is being initialized.
    /// Default: -1 (means no timeout)
    ///
    @objc public var sdkReadyTimeOut: Int = -1

    ///
    /// The SDK will poll Split servers for changes to feature flags at this rate (in seconds). Default 3600 (1 hour)
    ///
    @objc public var featuresRefreshRate: Int = 3600

    ///
    /// The treatment log captures which customer saw what treatment ("on", "off", etc) at what time.
    // This log is periodically flushed back to Split servers.
    /// This configuration controls how quickly does the cache expire after a write (in seconds).
    /// Default: 1800 seconds (30 minutes)
    ///
    @objc public var impressionRefreshRate: Int = 1800

    /// Maximum number of impressions to send in one block to the server.
    /// Default 100
    @objc public var impressionsChunkSize: Int64 = 100

    ///
    /// The SDK will poll Split servers for changes to segments at this rate (in seconds).
    /// Default: 1800 seconds (30 minutes)
    ///
    @objc public var segmentsRefreshRate: Int = 1800

    ///
    /// Default queue size for impressions. Default: 30K
    ///
    @objc public var impressionsQueueSize: Int = ServiceConstants.impressionsQueueSize

    ///
    /// Timeout for HTTP calls in seconds. Default 30 seconds
    ///
    @objc public var connectionTimeout: Int = 30

    ///
    /// The traffic type associated with the client key.
    /// If it’s present, it’s binded to the client instance, exactly as the key.
    /// If not, we will expect the traffic type on each .track() call. This is an optional value.
    ///
    @objc public var trafficType: String?

    ///
    /// How much will we wait for the first events flush. Default: 10s.
    ///
    @objc public var eventsFirstPushWindow: Int = 10

    ///
    /// The schedule time for events flush after the first one. Default:  1800 seconds (30 minutes)
    ///
    @objc public var eventsPushRate: Int = 1800

    ///
    /// The max size of the events queue. If the queue is full, we should flush. Default: 10000
    ///
    @objc public var eventsQueueSize: Int64 = 10000

    ///
    /// The amount of events to send in a POST request. Default: 2000
    ///
    @objc public var eventsPerPush: Int = ServiceConstants.eventsPerPush

    ///
    /// The schedule time for metrics flush after the first one. Default:  1800 seconds (30 minutes)
    ///
    @objc public var metricsPushRate: Int = 1800

    ///
    /// Client API key for company. Get it from Split admin dashboard.
    ///
    @objc public var apiKey: String {
        get {
            return SecureDataStore.shared.getToken() ?? ""
        }
        set {
            SecureDataStore.shared.setToken(token: newValue)
        }

    }

    @objc public var serviceEndpoints = ServiceEndpoints.builder().build()

    ///
    /// Enables debug messages in console.
    /// This method is deprecated in favor of logLevel.
    ///
    @available(*, deprecated, message: "Use logLevel instead")
    @objc public var isDebugModeEnabled: Bool {
        get {
            return Logger.shared.level == .debug
        }
        set {
            if Logger.shared.level == .none {
                Logger.shared.level = newValue ? .debug : .none
            }
        }
    }

    ///
    //// Enables verbose messages in console.
    /// This method is deprecated in favor of logLevel.
    ///
    @available(*, deprecated, message: "Use logLevel instead")
    @objc public var isVerboseModeEnabled: Bool {
        get {
            return Logger.shared.level == .verbose
        }
        set {
            if Logger.shared.level == .none {
                Logger.shared.level = newValue ? .verbose : .none
            }
        }
    }

    /// Set the log level
    /// Swift only method
    public var logLevel: SplitLogLevel {
        get {
            return Logger.shared.level
        }
        set {
            Logger.shared.level = newValue
        }
    }

    @objc public func set(logLevel: String) {
        Logger.shared.level = SplitLogLevel(rawValue: logLevel) ?? .none
    }

    ///
    /// Enables / Disables cache data encryption (Default: False)
    ///
    @objc public var encryptionEnabled: Bool = false

    ///
    /// The logic to handle an impression log generated during a getTreatment call
    /// - Parameters
    /// - A closure of type SplitImpressionListener, that means (SplitImpression) -> Void
    ///
    @objc public var impressionListener: SplitImpressionListener?

    ///
    /// Data folder to store localhost feature flags file
    /// - Default: localhost
    ///
    @objc public var localhostDataFolder: String = "localhost"

    ///
    /// Localhost feature flags file name
    ///
    @objc public var splitFile: String = "localhost.splits"

    ///
    /// Enable labels for impressions
    ///
    @objc public var isLabelsEnabled = true

    ///
    /// Allows  to pass a list of filters for the feature flags that will be downloaded
    /// Use the SyncConfig builder and Feature flag Filter class to build correct filters
    ///
    @objc public var sync = SyncConfig.builder().build()

    /// Whether we should attempt to use streaming or not. If the variable is false,
    /// the SDK will start in polling mode and stay that way.
    /// Default: true
    ///
    @objc public var streamingEnabled = true

    /// Setup the impressions mode.
    /// @param mode Values:<br>
    ///     DEBUG: All impressions are sent and
    ///     OPTIMIZED: Will send unique impressions in a timeframe in order to reduce how
    ///     many times impressions are posted.
    ///     NONE: Only capture unique keys evaluated for a particular feature flag instead of full blown impressions.
    ///
    /// @return: This builder
    /// @default: OPTIMIZED
    ///
    @ImpressionsModeProperty @objc public var impressionsMode: String = "OPTIMIZED"

    ///
    /// How many seconds to wait before re attempting the whole connection flow
    /// Hard upper limit: 30 minutes (no configurable)

    /// Default: 1
    ///

    @objc public var pushRetryBackoffBase = 1 {
        didSet {
            if pushRetryBackoffBase < 1 || pushRetryBackoffBase > 1800 {
                Logger.w("pushRetryBackoffBase must be a value in seconds between 1 and 1800 (30 minutes). " +
                    "Resetting it to 1 second")
                pushRetryBackoffBase = 1
            }
        }
    }

    ///
    /// The SDK will load changes from feature flags files base on this feature. Default = -1 (Deactivated)
    ///
    @objc public var offlineRefreshRate: Int = -1

    ///
    /// When set to true app sync is done while app is in background.
    /// Otherwise synchronization only occurs while app
    /// is in foreground
    ///
    @objc public var synchronizeInBackground = false

    /// Indicates if events and impressions are tracked and sent to BE.
    /// @param mode Values:<br>
    ///     UNKNOWN: Impressions and events are tracked in memory. They are lost on destroy
    ///     GRANTED: Impressions and events are tracked and sent. They remain stored when the SDK is destroyed.
    ///              If previous value was UNKNOWN, tracked data is persisted.
    ///     DECLINED: Impressions and events are not tracked nor sent.
    ///              if previous value was UNKNOWN, tracked data is cleared.
    ///
    /// @return: This builder
    /// @default: GRANTED
    ///
    public var userConsent: UserConsent = UserConsent.granted

    ///
    ///    Allows to perform a custom authentication on HTTPS requests.
    ///    This component must implement SplitHttpsAuthenticator protocol.
    ///    The function _authenticate:session:challenge:completionHandler_ will be executed when the
    ///     [urlSession(_:didReceive:completionHandler:)]
    ///     (https://developer.apple.com/documentation/foundation/urlsessiondelegate/1409308-urlsession) is called.
    ///
    @objc public var httpsAuthenticator: SplitHttpsAuthenticator?

    static let kDefaultTelemetryRefreshRate = 3600
    static let kMinTelemetryRefreshRate = 60
    ///
    /// The schedule time for telemetry flush after the first one.
    /// Default: 3600 seconds (1 hour)
    ///
    @objc public var telemetryRefreshRate: Int =  kDefaultTelemetryRefreshRate {
        didSet {
            if telemetryRefreshRate < SplitClientConfig.kMinTelemetryRefreshRate {
                internalTelemetryRefreshRate =  SplitClientConfig.kMinTelemetryRefreshRate
                Logger.w("Telemetry refresh rate lower than allowed. " +
                            "Using minimum allowed value: \(SplitClientConfig.kMinTelemetryRefreshRate) seconds.")
            } else {
                internalTelemetryRefreshRate = telemetryRefreshRate
            }
        }
    }

    var internalTelemetryRefreshRate: Int = kDefaultTelemetryRefreshRate

    ///
    /// Maximum length matching / bucketing key. Internal config
    ///
    let maximumKeyLength = 250

    ///
    /// Default folder to store cached data
    ///
    let defaultDataFolder = ServiceConstants.defaultDataFolder

    ///
    /// Max events queue memory size in bytes (5mb)
    ///
    let maxEventsQueueMemorySizeInBytes = 5242880

    ///
    /// Event without properties estimated size in bytes
    ///
    let initialEventSizeInBytes = 1024

    ///
    /// Time to consider that cache has expired
    ///
    let cacheExpirationInSeconds = ServiceConstants.cacheExpirationInSeconds

    let sseHttpClientConnectionTimeOut: TimeInterval = 80

    var generalRetryBackoffBase = 1

    /// Make it mutable to allow testing
    var impressionsCountsRefreshRate = 1800

    ///
    /// Make it mutable to allow testing (Default: false)
    /// Enables persistent storage for common attributes  given by the user during the SDK
    /// lifecycle to use them in every evaluation.
    /// If this flags is set to false, attributes will be stored in memory only and their values
    ///  will be lost in SDK detroy.
    ///
    @objc public var persistentAttributesEnabled = false

    ///
    /// Sync all retrieved data only once on init (Default: false)
    /// No streaming neither polling service is enabled.
    /// To get last definitions, the SDK have to be recreated
    @objc public var syncEnabled = true

    ///
    /// Prefix applied to the cache database name (Default: nil)
    /// This is useful when using two factories with the same SDK Key to avoid having issues with the shared data
    @objc public var prefix: String?

    /// The `CertificatePinningConfig` class is used to configure certificate pinning for a given set of hosts.
    /// It holds an array of credentials, each of which represents a pin for a specific host,
    /// either in the form of a certificate name or a base64-encoded key hash.
    /// This configuration ensures that only trusted certificates are used for secure communication.
    ///
    /// ### Usage Example:
    /// ```swift
    /// // Create a new builder instance
    /// let builder = CertificatePinningConfig.builder()
    ///
    /// // Add certificate pin for a host
    /// builder.addPin(host: "example.com", certificateName: "example_cert")
    ///
    /// // Add key hash pin for a host
    /// builder.addPin(host: "example.com", keyHash: "sha256/aGVsbG8gd29ybGQ=")
    ///
    /// // Build the CertificatePinningConfig
    /// let config = try builder.build()
    /// ```
    ///
    /// This example demonstrates how to add certificate and key hash pins for a host and build the configuration.
    ///
    /// - Note: The certificate files must be in DER format and included in the app bundle.
    @objc public var certificatePinningConfig: CertificatePinningConfig?

    ///
    ///  Update this variable to enable / disable telemetry for testing
    ///

    /// WARNING!!!
    /// This property is public only for testing purposes.
    /// That's why is only public for when ENABLE_TELEMETRY_ALWAYS flag is present
    /// Do not change this property
    #if ENABLE_TELEMETRY_ALWAYS
    public var telemetryConfigHelper: TelemetryConfigHelper = DefaultTelemetryConfigHelper()
    #else
    var telemetryConfigHelper: TelemetryConfigHelper = DefaultTelemetryConfigHelper()
    #endif

    // This variable will be handled internaly based on
    // a random function
    var isTelemetryEnabled: Bool {
        telemetryConfigHelper.shouldRecordTelemetry
    }

    // Is not a constant for testing purposes
    var uniqueKeysRefreshRate: Int = 900

    // CDN backoff time base - Not a constant for testing purposes
    var cdnByPassMaxAttempts: Int = 10
    var cdnBackoffTimeBaseInSecs: Int = 10
    var cdnBackoffTimeMaxInSecs: Int = 60

}

extension SplitClientConfig {
    func bySetsFilter() -> SplitFilter? {
        // Group the filters by type
        let groupedFilters = Dictionary(grouping: self.sync.filters) { $0.type }

        // Extract and combine values for 'bySet' type
        guard let sets = groupedFilters[.bySet]?.reduce(into: [String](), { result, filter in
            result.append(contentsOf: filter.values)
        }).sorted() else {
            return nil
        }

        return SplitFilter(type: .bySet, values: sets)

    }
}
