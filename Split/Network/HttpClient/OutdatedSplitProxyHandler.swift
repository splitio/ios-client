//
//  OutdatedSplitProxyHandler.swift
//  Split
//
//  Created on 13/05/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation

/// Handles proxy spec fallback and recovery.
///
/// This class manages the state machine that determines which spec version (latest or legacy) should be used
/// to communicate with the Split Proxy, based on observed proxy compatibility errors.
/// It ensures that the SDK can automatically fall back to a legacy spec when the proxy is outdated, periodically
/// attempt recovery, and return to normal operation if the proxy is upgraded.
///
/// State Machine:
/// - NONE: Normal operation, using latest spec. Default state.
/// - FALLBACK: Entered when a proxy error is detected with the latest spec. SDK uses legacy spec and omits RB_SINCE param.
/// - RECOVERY: Entered after fallback interval elapses. SDK attempts to use latest spec again. If successful, returns to NONE.
///
/// Transitions:
/// - NONE --(proxy error w/ latest spec)--> FALLBACK
/// - FALLBACK --(interval elapsed)--> RECOVERY
/// - RECOVERY --(success w/ latest spec)--> NONE
/// - RECOVERY --(proxy error)--> FALLBACK
/// - FALLBACK --(generic 400)--> FALLBACK (error surfaced, no state change)
///
/// Only an explicit proxy outdated error triggers fallback. Generic 400s do not.
class OutdatedSplitProxyHandler {

    /// Enum representing the proxy handling types.
    private enum ProxyHandlingType {
        /// No action
        case none
        /// Switch to previous spec
        case fallback
        /// Attempt recovery
        case recovery
    }

    private static let PREVIOUS_SPEC = "1.2"

    private let latestSpec: String
    private let previousSpec: String
    private let proxyCheckIntervalMillis: Int64
    
    private var lastProxyCheckTimestamp: Int64 = 0
    private let generalInfoStorage: GeneralInfoStorage
    private var currentProxyHandlingType: ProxyHandlingType = .none
    
    /// Initializes a new OutdatedSplitProxyHandler with default previous spec.
    ///
    /// - Parameters:
    ///   - flagSpec: The latest spec version
    ///   - generalInfoStorage: The general info storage
    ///   - proxyCheckIntervalMillis: The custom proxy check interval
    convenience init(flagSpec: String, generalInfoStorage: GeneralInfoStorage, proxyCheckIntervalMillis: Int64) {
        self.init(flagSpec: flagSpec, previousSpec: OutdatedSplitProxyHandler.PREVIOUS_SPEC, generalInfoStorage: generalInfoStorage, proxyCheckIntervalMillis: proxyCheckIntervalMillis)
    }

    /// Initializes a new OutdatedSplitProxyHandler with custom previous spec.
    ///
    /// - Parameters:
    ///   - flagSpec: The latest spec version
    ///   - previousSpec: The previous spec version
    ///   - generalInfoStorage: The general info storage
    ///   - proxyCheckIntervalMillis: The custom proxy check interval
    init(flagSpec: String, previousSpec: String, generalInfoStorage: GeneralInfoStorage, proxyCheckIntervalMillis: Int64) {
        self.latestSpec = flagSpec
        self.previousSpec = previousSpec
        self.proxyCheckIntervalMillis = proxyCheckIntervalMillis
        self.generalInfoStorage = generalInfoStorage
    }

    /// Tracks a proxy error and updates the state machine accordingly.
    func trackProxyError() {
        updateLastProxyCheckTimestamp(Date.nowMillis())
        updateHandlingType(.fallback)
    }

    /// Performs a periodic proxy check to attempt recovery.
    func performProxyCheck() {
        let lastTimestamp = getLastProxyCheckTimestamp()
        
        if lastTimestamp == 0 {
            updateHandlingType(.none)
        } else if Date.nowMillis() - lastTimestamp > proxyCheckIntervalMillis {
            Logger.i("Time since last check elapsed. Attempting recovery with latest spec: \(latestSpec)")
            updateHandlingType(.recovery)
        } else {
            Logger.v("Have used proxy fallback mode; time since last check has not elapsed. Using previous spec")
            updateHandlingType(.fallback)
        }
    }

    /// Resets the proxy check timestamp.
    func resetProxyCheckTimestamp() {
        updateLastProxyCheckTimestamp(0)
    }

    /// Returns the current spec version based on the state machine.
    ///
    /// - Returns: The current spec version
    func getCurrentSpec() -> String {
        if currentProxyHandlingType == .fallback {
            return previousSpec
        }
        return latestSpec
    }

    /// Indicates whether the SDK is in fallback mode.
    ///
    /// - Returns: true if in fallback mode, false otherwise
    func isFallbackMode() -> Bool {
        return currentProxyHandlingType == .fallback
    }

    /// Indicates whether the SDK is in recovery mode.
    ///
    /// - Returns: true if in recovery mode, false otherwise
    func isRecoveryMode() -> Bool {
        return currentProxyHandlingType == .recovery
    }

    private func updateHandlingType(_ proxyHandlingType: ProxyHandlingType) {
        currentProxyHandlingType = proxyHandlingType
    }

    private func getLastProxyCheckTimestamp() -> Int64 {
        if lastProxyCheckTimestamp == 0 {
            lastProxyCheckTimestamp = generalInfoStorage.getLastProxyUpdateTimestamp()
        }
        return lastProxyCheckTimestamp
    }

    private func updateLastProxyCheckTimestamp(_ newTimestamp: Int64) {
        lastProxyCheckTimestamp = newTimestamp
        generalInfoStorage.setLastProxyUpdateTimestamp(lastProxyCheckTimestamp)
    }
}
