//
//  SplitFactory.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

public class SplitFactory: NSObject, SplitFactoryProtocol {

    let _client: SplitClientProtocol
    let _manager: SplitManagerProtocol
    let kValidationTag = "factory instantiation"

    @objc(initWithApiKey:key:config:) public init(apiKey: String, key: Key, config: SplitClientConfig) {
        HttpSessionConfig.default.connectionTimeOut = TimeInterval(config.connectionTimeout)
        MetricManagerConfig.default.pushRateInSeconds = config.metricsPushRate
        ValidationConfig.default.maximumKeyLength = config.maximumKeyLength

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
