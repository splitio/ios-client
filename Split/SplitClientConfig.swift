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
    private var apiKey: String? { return SecureDataStore.shared.getToken() }
    
    public func debug(_ d:Bool){
        Logger.shared.debugLevel(debug: d)
    }
    
    public func verbose(_ v:Bool){
        Logger.shared.verboseLevel(verbose: v)
    }
    
    public func featuresRefreshRate(_ rr: Int) {
        self.featuresRefreshRate = rr
    }
    
    public func getFeaturesRefreshRate() -> Int {
        return self.featuresRefreshRate
    }
    
    public func segmentsRefreshRate(_ rr: Int) {
        self.segmentsRefreshRate = rr
    }
    
    public func getSegmentsRefreshRate() -> Int {
        return self.segmentsRefreshRate
    }
    
    public func impressionRefreshRate(_ rr: Int){
        self.impressionRefreshRate = rr
    }
    
    public func getImpressionRefreshRate() -> Int {
        return self.impressionRefreshRate
    }
    
    public func impressionsChunkSize(_ cs: Int64) {
        self.impressionsChunkSize = cs
    }
    
    public func getImpressionsChunkSize() -> Int64 {
        return self.impressionsChunkSize
    }
    
    
    public func impressionsQueueSize(_ qs: Int) {
        self.impressionsQueueSize = qs
    }
    
    public func getImpressionsQueueSize() -> Int {
        return self.impressionsQueueSize
    }
    
    public func connectionTimeout(_ to: Int) {
        self.connectionTimeout = to
    }
    
    public func getConnectionTimeout() -> Int {
        return self.connectionTimeout
    }

    public func apiKey(_ k: String) {
        SecureDataStore.shared.setToken(token: k)
    }
    
    public func getApiKey() -> String {
        return self.apiKey!
    }
    
    public func sdkEndpoint(_ u: String) {
        EnvironmentTargetManager.shared.sdkEndpoint(u)
    }
    
    public func eventsEndpoint(_ u: String) {
        EnvironmentTargetManager.shared.eventsEndpoint(u)
    }
}
