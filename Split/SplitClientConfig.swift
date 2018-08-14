//
//  SplitConfig.swift
//  Pods
//
//  Created by Brian Sztamfater on 21/9/17.
//
//

import Foundation

public class SplitClientConfig: NSObject {
    
    
    public var sdkReadyTimeOut: Int = -1
    public var featuresRefreshRate: Int = 3600
    public var impressionRefreshRate: Int = 1800
    public var impressionsChunkSize: Int64 = 100
    public var segmentsRefreshRate: Int = 1800
    public var impressionsQueueSize: Int = 30000
    public var connectionTimeout: Int = 15000
    
    /**
     The traffic type associated with the client key. If it’s present, it’s binded to the client instance, exactly as the key. If not, we will expect the traffic type on each .track() call. This is an optional value.
     */
    public var trafficType: String? = nil
    
    /**
     How much will we wait for the first events flush. Default: 10s.
     */
    public var eventsFirstPushWindow: Int = 10
    
    /**
     The schedule time for events flush after the first one. Default: 10s
     */
    public var eventsPushRate: Int = 1800
    
    /**
     The max size of the events queue. If the queue is full, we should flush. Default: 10000
     */
    public var eventsQueueSize: Int64 = 10000
    
    /**
     The amount of events to send in a POST request. Default: 2000
     */
    public var eventsPerPush: Int = 2000
    
    
    public var apiKey: String {
        get {
            return SecureDataStore.shared.getToken() ?? ""
        }
        set {
            SecureDataStore.shared.setToken(token: newValue)
        }
        
    }
    
    public func debug(_ d:Bool){
        Logger.shared.debugLevel(debug: d)
    }
    
    public func verbose(_ v:Bool){
        Logger.shared.verboseLevel(verbose: v)
    }
}

// MARK: Deprecated methods

// MARK: Event track Settings
extension SplitClientConfig {
    @available(*, deprecated, renamed: "sdkReadyTimeOut", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead. Please use equivalent propery instead Please use equivalent propery instead")
    public func readyTimeOut(_ readyInMillis: Int){
        self.sdkReadyTimeOut = readyInMillis
    }
    
    @available(*, deprecated, renamed: "sdkReadyTimeOut", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func getReadyTimeOut() -> Int {
        return self.sdkReadyTimeOut
    }
    
    
    @available(*, deprecated, renamed: "featuresRefreshRate", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func featuresRefreshRate(_ rr: Int) {
        self.featuresRefreshRate = rr
    }
    
    @available(*, deprecated, renamed: "featuresRefreshRate", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func getFeaturesRefreshRate() -> Int {
        return self.featuresRefreshRate
    }
    
    @available(*, deprecated, renamed: "segmentsRefreshRate", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func segmentsRefreshRate(_ rr: Int) {
        self.segmentsRefreshRate = rr
    }
    
    @available(*, deprecated, renamed: "segmentsRefreshRate", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func getSegmentsRefreshRate() -> Int {
        return self.segmentsRefreshRate
    }
    
    @available(*, deprecated, renamed: "impressionRefreshRate", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func impressionRefreshRate(_ rr: Int){
        self.impressionRefreshRate = rr
    }
    
    @available(*, deprecated, renamed: "impressionRefreshRate", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func getImpressionRefreshRate() -> Int {
        return self.impressionRefreshRate
    }
    
    @available(*, deprecated, renamed: "impressionsChunkSize", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func impressionsChunkSize(_ cs: Int64) {
        self.impressionsChunkSize = cs
    }
    
    @available(*, deprecated, renamed: "impressionsChunkSize", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func getImpressionsChunkSize() -> Int64 {
        return self.impressionsChunkSize
    }
    
    @available(*, deprecated, renamed: "impressionsQueueSize", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func impressionsQueueSize(_ qs: Int) {
        self.impressionsQueueSize = qs
    }
    
    @available(*, deprecated, renamed: "impressionsQueueSize", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func getImpressionsQueueSize() -> Int {
        return self.impressionsQueueSize
    }
    
    @available(*, deprecated, renamed: "connectionTimeout", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func connectionTimeout(_ to: Int) {
        self.connectionTimeout = to
    }
    
    @available(*, deprecated, renamed: "connectionTimeout", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func getConnectionTimeout() -> Int {
        return self.connectionTimeout
    }

    @available(*, deprecated, renamed: "apiKey", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func apiKey(_ k: String) {
        SecureDataStore.shared.setToken(token: k)
    }
    
    @available(*, deprecated, renamed: "apiKey", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func getApiKey() -> String {
        return self.apiKey
    }
    
    @available(*, deprecated, renamed: "sdkReadyTimeOut", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func sdkEndpoint(_ u: String) {
        EnvironmentTargetManager.shared.sdkEndpoint(u)
    }
    
    @available(*, deprecated, renamed: "sdkReadyTimeOut", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func eventsEndpoint(_ u: String) {
        EnvironmentTargetManager.shared.eventsEndpoint(u)
    }
}

// MARK: Event track Settings
extension SplitClientConfig {
    
    @available(*, deprecated, renamed: "trafficType", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func trafficType(_ tt: String){
        self.trafficType = tt
    }
    
    @available(*, deprecated, renamed: "trafficType", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func getTrafficType() -> String? {
        return self.trafficType
    }
    
    @available(*, deprecated, renamed: "eventsFirstPushWindow", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func eventsFirstPushWindow(_ pw: Int){
        self.eventsFirstPushWindow = pw
    }
    
    @available(*, deprecated, renamed: "eventsFirstPushWindow", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func getEventsFirstPushWindow() -> Int {
        return self.eventsFirstPushWindow
    }
    
    @available(*, deprecated, renamed: "eventsPushRate", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func eventsPushRate(_ pr: Int){
        self.eventsPushRate = pr
    }
    
    @available(*, deprecated, renamed: "eventsPushRate", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func getEventsPushRate() -> Int {
        return self.eventsPushRate
    }
    
    @available(*, deprecated, renamed: "eventsQueueSize", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func eventsQueueSize(_ qs: Int64) {
        self.eventsQueueSize = qs
    }
    
    @available(*, deprecated, renamed: "eventsQueueSize", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func getEventsQueueSize() -> Int64 {
        return self.eventsQueueSize
    }
    
    @available(*, deprecated, renamed: "eventsPerPush", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func eventsPerPush(_ pp: Int) {
        self.eventsPerPush = pp
    }
    
    @available(*, deprecated, renamed: "eventsPerPush", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead")
    public func getEventsPerPush() -> Int {
        return self.eventsPerPush
    }
}
