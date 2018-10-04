//
//  SplitConfig.swift
//  Pods
//
//  Created by Brian Sztamfater on 21/9/17.
//
//

import Foundation

public typealias SplitImpressionListener = (SplitImpression) -> Void

public class SplitClientConfig: NSObject {

    /**
     How many seconds to wait before triggering a timeout event when the SDK is being initialized. Default: -1 (means no timeout)
     */
    public var sdkReadyTimeOut: Int = -1

    /**
    The SDK will poll Split servers for changes to feature Splits at this rate (in seconds). Default 3600 (1 hour)
     */
    public var featuresRefreshRate: Int = 3600

    /**
     The treatment log captures which customer saw what treatment ("on", "off", etc) at what time. This log is periodically flushed back to Split servers. This configuration controls how quickly does the cache expire after a write (in seconds). Default: 1800 seconds (30 minutes)
     */
    public var impressionRefreshRate: Int = 1800

    /**
     */
    public var impressionsChunkSize: Int64 = 100

    /**
     The SDK will poll Split servers for changes to segments at this rate (in seconds). Default: 1800 seconds (30 minutes)
     */
    public var segmentsRefreshRate: Int = 1800

    /**
     Default queue size for impressions. Default: 30K
     */
    public var impressionsQueueSize: Int = 30000

    /**
     Timeout for HTTP calls in seconds. Default 30 seconds
     */
    public var connectionTimeout: Int = 30

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

    /**
     Client API key for company. Get it from Split admin dashboard.
     */
    public var apiKey: String {
        get {
            return SecureDataStore.shared.getToken() ?? ""
        }
        set {
            SecureDataStore.shared.setToken(token: newValue)
        }

    }

    /**
     Sdk endpoint URL string.
     */
    public var targetSdkEndPoint: String {
        get {
            return EnvironmentTargetManager.shared.sdkEndpoint
        }
        set {
            EnvironmentTargetManager.shared.sdkEndpoint = newValue
        }
    }

    /**
     Events endpoint URL string.
     */
    public var targetEventsEndPoint: String {
        get {
            return EnvironmentTargetManager.shared.eventsEndpoint
        }
        set {
            EnvironmentTargetManager.shared.eventsEndpoint = newValue
        }
    }

    /**
     Enables debug messages in console
     */
    public var isDebugModeEnabled: Bool {
        get {
            return Logger.shared.isDebugModeEnabled
        }
        set {
            Logger.shared.isDebugModeEnabled = newValue
        }
    }

    /**
     Enables verbose mode. All Sdk messages will be logged in console
     */
    public var isVerboseModeEnabled: Bool {
        get {
            return Logger.shared.isVerboseModeEnabled
        }
        set {
            Logger.shared.isVerboseModeEnabled = newValue
        }
    }
    
    /**
     The logic to handle an impression log generated during a getTreatment call
        - Parameters
        - A closure of type SplitImpressionListener, that means (SplitImpression) -> Void
     */
    public var impressionListener: SplitImpressionListener?
}

// MARK: Deprecated methods
/**
 All this methods are deprecated and will be removed on next versions. Should use properties instead.
 */
extension SplitClientConfig {
    @available(*, deprecated, renamed: "sdkReadyTimeOut", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead.")
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

    @available(*, deprecated, renamed: "isDebugModeEnabled", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead.")
    public func debug(_ d:Bool){
        Logger.shared.isDebugModeEnabled = d
    }

    @available(*, deprecated, renamed: "isVerboseModeEnabled", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead.")
    public func verbose(_ v:Bool){
        Logger.shared.isVerboseModeEnabled = v
    }

    @available(*, deprecated, renamed: "sdkEndpoint", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead.")
    public func sdkEndpoint(_ u: String) {
        EnvironmentTargetManager.shared.sdkEndpoint = u
    }

    @available(*, deprecated, renamed: "eventsEndpoint", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead.")
    public func eventsEndpoint(_ u: String) {
        EnvironmentTargetManager.shared.eventsEndpoint = u
    }
    
    @available(*, deprecated, renamed: "impressionListener", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead.")
    public func setImpressionListener(_ il: @escaping SplitImpressionListener){
        impressionListener = il
    }
    
    @available(*, deprecated, renamed: "impressionListener", message: "This function was deprecated and will be removed in future versions. Please use equivalent propery instead.")
    public func getImpressionListener() -> SplitImpressionListener? {
        return impressionListener
    }
}
