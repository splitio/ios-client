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
    var segmentsRefreshRate: Int
    var impressionsRefreshRate: Int
    var impressionsQueueSize: Int
    var connectionTimeout: Int
    var debugEnabled: Bool
    var blockUntilReady: Int
    
    // TODO: Add pending parameters
    public init(featuresRefreshRate: Int? = 30, segmentsRefreshRate: Int? = 30, impressionsRefreshRate: Int? = 30, impressionsQueueSize: Int? = 30000, connectionTimeout: Int? = 15000, debugEnabled: Bool? = false, blockUntilReady: Int? = -1) {
        self.featuresRefreshRate = featuresRefreshRate!
        self.segmentsRefreshRate = segmentsRefreshRate!
        self.impressionsRefreshRate = impressionsRefreshRate!
        self.impressionsQueueSize = impressionsQueueSize!
        self.connectionTimeout = connectionTimeout!
        self.debugEnabled = debugEnabled!
        self.blockUntilReady = blockUntilReady!
    }
    
}
