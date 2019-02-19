//
//  DefaultSplitFactoryBuilder.swift
//  Split
//
//  Created by Javier L. Avrudsky on 31/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

///
/// Default implementation of factory builder.
/// This class is intended to use as a kind of Director in the future. It will use
/// another concrete class implementing the same protocol to build the factory.
/// The idea is to avoid some boilerplate code when creating the factory.
/// For now it's just the defaul factory.
/// 
@objc public class DefaultSplitFactoryBuilder: NSObject, SplitFactoryBuilder {
    
    private var apiKey: String?
    private var matchingKey: String?
    private var bucketingKey: String?
    private var key: Key?
    private var config: SplitClientConfig?
    private var kApiKeyLocalhost = "LOCALHOST"
    
    public func setApiKey(_ apiKey: String) -> SplitFactoryBuilder {
        self.apiKey = apiKey
        return self
    }
    
    public func setMatchingKey(_ matchingKey: String) -> SplitFactoryBuilder {
        self.matchingKey = matchingKey
        return self
    }
    
    public func setBucketingKey(_ bucketingKey: String) -> SplitFactoryBuilder {
        self.bucketingKey = bucketingKey
        return self
    }
    
    public func setKey(_ key: Key) -> SplitFactoryBuilder {
        self.key = key
        return self
    }
    
    public func setConfig(_ config: SplitClientConfig) -> SplitFactoryBuilder {
        self.config = config
        return self
    }
    
    public func build() -> SplitFactory? {
        if apiKey?.uppercased() == kApiKeyLocalhost {
            return LocalhostSplitFactory(config: config ?? SplitClientConfig())
        }
        
        if apiKey == nil || (key == nil && matchingKey == nil) {
            return nil
        }
        
        return DefaultSplitFactory(apiKey: apiKey!,
                                   key: (key ?? Key(matchingKey: matchingKey!, bucketingKey: bucketingKey)),
                                   config: config ?? SplitClientConfig())
    }
}
