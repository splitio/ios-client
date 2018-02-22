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
    
    public init(key: Key, config: SplitClientConfig) {
        // TODO: Use apiKey, review and refactor client parameters
        let client = SplitClient(config: config, key: key)
        _client = client 
        _manager = SplitManager()
        
        Logger.i("iOS SDK initialized!")
    }

    public func client() -> SplitClientTreatmentProtocol {
        return _client
    }
    
    public func manager() -> SplitManagerProtocol {
        return _manager
    }
    
}
