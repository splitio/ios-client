//
//  SplitConfig.swift
//  Pods
//
//  Created by Brian Sztamfater on 21/9/17.
//
//

import Foundation

public class SplitClientConfig: NSObject {
    
    var featuresRefreshRate: Int
    var impressionRefreshRate: Int
    var impressionsChunkSize: Int64
    var segmentsRefreshRate: Int
    var impressionsRefreshRate: Int
    var impressionsQueueSize: Int
    var connectionTimeout: Int
    var debugEnabled: Bool
    var blockUntilReady: Int
    var environment: SplitEnvironment
    var apiKey: String? { return SecureDataStore.shared.getToken() }
    
    // TODO: Add pending parameters
    public init(featuresRefreshRate: Int? = 30, segmentsRefreshRate: Int? = 30, impressionsRefreshRate: Int? = 30, impressionsQueueSize: Int? = 30000, connectionTimeout: Int? = 15000, debugEnabled: Bool? = false, blockUntilReady: Int? = -1, impressionRefreshRate: Int? = 30, impressionsChunkSize: Int64 = 100 , environment: SplitEnvironment, apiKey: String) {
        self.featuresRefreshRate = featuresRefreshRate!
        self.segmentsRefreshRate = segmentsRefreshRate!
        self.impressionsRefreshRate = impressionsRefreshRate!
        self.impressionsQueueSize = impressionsQueueSize!
        self.connectionTimeout = connectionTimeout!
        self.debugEnabled = debugEnabled!
        self.blockUntilReady = blockUntilReady!
        self.impressionRefreshRate = impressionRefreshRate!
        self.environment = environment
        SecureDataStore.shared.setToken(token: apiKey)
        self.impressionsChunkSize = impressionsChunkSize
        
        if (debugEnabled == true) {
            Logger.shared.debugLevel(debug: true)
        }
    }
    
    
    
}
