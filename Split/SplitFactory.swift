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
    
    //TODO Add API-KEY as first parameter and remove it from config class
    public init(key: Key, config: SplitClientConfig) {
        
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
