//
//  SplitFactory.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

@objc public class SplitFactory: NSObject, SplitFactoryProtocol {
    
    let _splitClient: SplitClientProtocol
    let _splitManager: SplitManagerProtocol
    
    public init(apiToken: String, config: SplitClientConfig) throws {
        // TODO: Use apiKey, review and refactor client parameters
        let splitClient = try SplitClient(fetcher: HttpSplitFetcher(), persistence: PlistSplitPersistence(fileName: "splits"), config: config)
        _splitClient = splitClient
        _splitManager = SplitManager()
    }

    public func splitClient() -> SplitClientProtocol {
        return _splitClient
    }
    
    public func splitManager() -> SplitManagerProtocol {
        return _splitManager
    }
    
}
