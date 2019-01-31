//
//  SplitFactory.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

/**
 Default implementation of SplitManager protocol
 */
public class DefaultSplitFactory: NSObject, SplitFactory {
    
    private let defaultClient: SplitClient
    private let defaultManager: SplitManager
    
    public var client: SplitClient {
        return defaultClient
    }
    
    public var manager: SplitManager {
        return defaultManager
    }
    
    public var version: String {
        return Version.toString()
    }
    
    init(apiKey: String, key: Key, config: SplitClientConfig) {
        HttpSessionConfig.default.connectionTimeOut = TimeInterval(config.connectionTimeout)
        MetricManagerConfig.default.pushRateInSeconds = config.metricsPushRate
    
        config.apiKey = apiKey
        let splitCache = SplitCache()
        let splitFetcher: SplitFetcher = LocalSplitFetcher(splitCache: splitCache)
        
        defaultClient = DefaultSplitClient(config: config, key: key, splitCache: splitCache)
        defaultManager = DefaultSplitManager(splitFetcher: splitFetcher)
    }
}
