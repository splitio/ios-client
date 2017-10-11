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
    
    public init(apiToken: String, config: SplitClientConfig) throws {
        // TODO: Use apiKey, review and refactor client parameters
        let splitClient = try SplitClient(fetcher: HttpSplitFetcher(), persistence: PlistSplitPersistence(fileName: "splits"), config: config)
        _client = splitClient
        _manager = SplitManager()
    }

    public func client() -> SplitClientProtocol {
        return _client
    }
    
    public func manager() -> SplitManagerProtocol {
        return _manager
    }
    
}
