//
//  SplitFactory.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

@objc public class SplitFactory: NSObject, SplitFactoryProtocol {
    
    let _client: SplitClientTreatmentProtocol
    let _manager: SplitManagerProtocol
    
    public init(apiKey: String, key: Key, config: SplitClientConfig) throws {
        _ = config.apiKey(apiKey)
        // TODO: Use apiKey, review and refactor client parameters
        let client = try SplitClient(config: config, key: key)
        _client = client 
        _manager = SplitManager()
    }

    public func client() -> SplitClientTreatmentProtocol {
        return _client
    }
    
    public func manager() -> SplitManagerProtocol {
        return _manager
    }
    
}
