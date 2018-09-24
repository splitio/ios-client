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
        config.apiKey = apiKey
        let splitCache = SplitCache(storage: FileStorage())
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
