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
        let dataFolderName = DataFolderFactory().createFrom(apiKey: apiKey) ?? config.defaultDataFolder
        
        HttpSessionConfig.default.connectionTimeOut = TimeInterval(config.connectionTimeout)
        MetricManagerConfig.default.pushRateInSeconds = config.metricsPushRate
        MetricManagerConfig.default.defaultDataFolderName = dataFolderName
    
        config.apiKey = apiKey
        let fileStorage = FileStorage(dataFolderName: dataFolderName)
        let splitCache = SplitCache(fileStorage: fileStorage)
        let splitFetcher: SplitFetcher = LocalSplitFetcher(splitCache: splitCache)
        
        defaultClient = DefaultSplitClient(config: config, key: key, splitCache: splitCache, fileStorage: fileStorage)
        defaultManager = DefaultSplitManager(splitFetcher: splitFetcher)
    }    
}
