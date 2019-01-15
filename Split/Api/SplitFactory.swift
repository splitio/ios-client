//
//  SplitFactory.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

@objc public class SplitFactory: NSObject, SplitFactoryProtocol {
    
    let _client: SplitClientProtocol
    let _manager: SplitManagerProtocol
    
    public init(apiKey: String, key: Key, config: SplitClientConfig) {
        
        if apiKey.isEmpty() {
            Logger.e("factory instantiation: you passed \"\", api_key must be a non-empty string")
        }
        
        _ = key.isValid(validator: KeyValidator(tag: "factory instantiation"))
        
        HttpSessionConfig.default.connectionTimeOut = TimeInterval(config.connectionTimeout)
        MetricManagerConfig.default.pushRateInSeconds = config.metricsPushRate
    
        config.apiKey = apiKey
        let splitCache = SplitCache()
        let splitFetcher: SplitFetcher = LocalSplitFetcher(splitCache: splitCache)
        
        _client = SplitClient(config: config, key: key, splitCache: splitCache)
        _manager = SplitManager(splitFetcher: splitFetcher)
    }

    public func client() -> SplitClientProtocol {
        return _client
    }
    
    public func manager() -> SplitManagerProtocol {
        return _manager
    }
    
    public func version() -> String {
        return Version.toString()
    }
    
}
