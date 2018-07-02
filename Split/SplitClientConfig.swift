//
//  SplitConfig.swift
//  Pods
//
//  Created by Brian Sztamfater on 21/9/17.
//
//

import Foundation

public class SplitClientConfig: NSObject {
    
    private var sdkReadyTimeOut: Int = -1
    private var featuresRefreshRate: Int = 3600
    private var impressionRefreshRate: Int = 1800
    private var impressionsChunkSize: Int64 = 100
    private var segmentsRefreshRate: Int = 1800
    private var impressionsQueueSize: Int = 30000
    private var connectionTimeout: Int = 15000
    
    private var trafficType: String? = nil
    private var eventsFirstPushWindow: Int = 10
    private var eventsPushRate: Int = 1800
    private var eventsQueueSize: Int64 = 10000
    private var eventsPerPush: Int = 2000
    
    private var apiKey: String? { return SecureDataStore.shared.getToken() }
    
    public func readyTimeOut(_ readyInMillis: Int){
        self.sdkReadyTimeOut = readyInMillis
    }
    
    public func getReadyTimeOut() -> Int {
        return self.sdkReadyTimeOut
    }
    
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

// MARK: Event track Settings
extension SplitClientConfig {
    /**
     The traffic type associated with the client key. If it’s present, it’s binded to the client instance, exactly as the key. If not, we will expect the traffic type on each .track() call. This is an optional value.
     */
    public func trafficType(_ tt: String){
        self.trafficType = tt
    }
    
    public func getTrafficType() -> String? {
        return self.trafficType
    }
    
    /**
     How much will we wait for the first events flush. Default: 10s.
     */
    public func eventsFirstPushWindow(_ pw: Int){
        self.eventsFirstPushWindow = pw
    }
    
    public func getEventsFirstPushWindow() -> Int {
        return self.eventsFirstPushWindow
    }
    
    /**
     The schedule time for events flush after the first one. Default: 10s
     */
    public func eventsPushRate(_ pr: Int){
        self.eventsPushRate = pr
    }
    
    public func getEventsPushRate() -> Int {
        return self.eventsPushRate
    }
    
    /**
     The max size of the events queue. If the queue is full, we should flush. Default: 10000
     */
    public func eventsQueueSize(_ qs: Int64) {
        self.eventsQueueSize = qs
    }
    
    public func getEventsQueueSize() -> Int64 {
        return self.eventsQueueSize
    }
    
    /**
     The amount of events to send in a POST request. Default: 2000
     */
    public func eventsPerPush(_ pp: Int) {
        self.eventsPerPush = pp
    }
    
    public func getEventsPerPush() -> Int {
        return self.eventsPerPush
    }
}
