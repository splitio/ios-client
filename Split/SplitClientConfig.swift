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
    private var blockUntilReady: Int = -1
    private var environment: SplitEnvironment = SplitEnvironment.Production
    private var apiKey: String? { return SecureDataStore.shared.getToken() }
    
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
    
    public func blockUntilReady(_ bur: Int) {
        self.blockUntilReady = bur
    }
    
    public func getBlockUntilReady() -> Int {
        return self.blockUntilReady
    }
    
    public func environment(_ env: SplitEnvironment) {
        self.environment = env
    }
    
    public func getEnvironment() -> SplitEnvironment {
        return self.environment
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
    
    public func getSdkEndpoint() -> URL {
        return TargetConfiguration.shared.getSdkEndpoint()
    }
    
    public func getEventsEndpoint() -> URL {
        return TargetConfiguration.shared.getEventsEndpoint()
    }
}
