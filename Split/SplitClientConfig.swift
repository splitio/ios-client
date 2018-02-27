//
//  SplitConfig.swift
//  Pods
//
//  Created by Brian Sztamfater on 21/9/17.
//
//

import Foundation

public class SplitClientConfig: NSObject {
    
    private var featuresRefreshRate: Int = 3600
    private var impressionRefreshRate: Int = 1800
    private var impressionsChunkSize: Int64 = 100
    private var segmentsRefreshRate: Int = 1800
    private var impressionsQueueSize: Int = 30000
    private var connectionTimeout: Int = 15000
    private var debugEnabled: Bool = false
    private var verboseEnabled: Bool = false
    private var blockUntilReady: Int = -1
    private var sdkURL: String = "https://sdk.split.io/api"
    private var eventsURL: String = "https://events.split.io/api"
    
    private var apiKey: String? { return SecureDataStore.shared.getToken() }
    
    public func featuresRefreshRate(_ rr: Int) -> SplitClientConfig {
        self.featuresRefreshRate = rr
        return self
    }
    
    public func getFeaturesRefreshRate() -> Int {
        return self.featuresRefreshRate
    }
    
    public func segmentsRefreshRate(_ rr: Int) -> SplitClientConfig {
        self.segmentsRefreshRate = rr
        return self
    }
    
    public func getSegmentsRefreshRate() -> Int {
        return self.segmentsRefreshRate
    }
    
    public func impressionRefreshRate(_ rr: Int) -> SplitClientConfig {
        self.impressionRefreshRate = rr
        return self
    }
    
    public func getImpressionRefreshRate() -> Int {
        return self.impressionRefreshRate
    }
    
    public func impressionsChunkSize(_ cs: Int64) -> SplitClientConfig {
        self.impressionsChunkSize = cs
        return self
    }
    
    public func getImpressionsChunkSize() -> Int64 {
        return self.impressionsChunkSize
    }
    
    
    public func impressionsQueueSize(_ qs: Int) -> SplitClientConfig {
        self.impressionsQueueSize = qs
        return self
    }
    
    public func getImpressionsQueueSize() -> Int {
        return self.impressionsQueueSize
    }
    
    public func connectionTimeout(_ to: Int) -> SplitClientConfig {
        self.connectionTimeout = to
        return self
    }
    
    public func getConnectionTimeout() -> Int {
        return self.connectionTimeout
    }
    
    public func debugEnabled(_ enabled: Bool) -> SplitClientConfig {
        self.debugEnabled = enabled
        if (debugEnabled == true) {
            Logger.shared.debugLevel(debug: true)
        } else {
            Logger.shared.debugLevel(debug: false)
        }
        return self
    }
    
    public func verboseEnabled(_ enabled: Bool) -> SplitClientConfig {
        self.verboseEnabled = enabled
        if (verboseEnabled == true) {
            Logger.shared.verboseLevel(verbose: true)
        } else {
            Logger.shared.verboseLevel(verbose: false)
        }
        return self
    }
    
    public func blockUntilReady(_ bur: Int) -> SplitClientConfig {
        self.blockUntilReady = bur
        return self
    }
    
    public func getBlockUntilReady() -> Int {
        return self.blockUntilReady
    }
    
    
    public func sdkUrl(_ url: String) -> SplitClientConfig {
        self.sdkURL = url
        TargetConfiguration.sdkEndpoint(url: url)
        return self
    }
    
    public func getSdkUrl() -> String {
        return self.sdkURL
    }
    
    public func eventsUrl(_ url: String) -> SplitClientConfig {
        self.eventsURL = url
        TargetConfiguration.eventsEndpoint(url: url)
        return self
    }
    
    public func getEventsUrl() -> String {
        return self.eventsURL
    }
    
    public func apiKey(_ k: String) -> SplitClientConfig {
        SecureDataStore.shared.setToken(token: k)
        return self
    }
    
    public func getApiKey() -> String {
        return self.apiKey!
    }
}
