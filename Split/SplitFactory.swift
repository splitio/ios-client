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
    
    public init(apiKey:String, key: Key, config: SplitClientConfig) {
        
        //Setting apikey into configuration class
        _ = config.apiKey(apiKey)
    
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
