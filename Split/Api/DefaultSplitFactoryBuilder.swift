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
    
    private var bundle: Bundle = Bundle.main
    private var apiKey: String?
    private var matchingKey: String?
    private var bucketingKey: String?
    private var key: Key?
    private var config: SplitClientConfig?
    private let kApiKeyLocalhost = "LOCALHOST"
    private let keyValidator: KeyValidator
    private let apiKeyValidator: ApiKeyValidator
    private let validationLogger: ValidationMessageLogger
    private let validationTag = "factory instantiation"

    public override init() {
        keyValidator = DefaultKeyValidator()
        apiKeyValidator = DefaultApiKeyValidator()
        validationLogger = DefaultValidationMessageLogger()
        super.init()
    }

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
    
    func setBundle(_ bundle: Bundle) -> SplitFactoryBuilder {
        self.bundle = bundle
        return self
    }

    public func build() -> SplitFactory? {
        

        if let errorInfo = apiKeyValidator.validate(apiKey: apiKey) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            return nil
        }

        let matchingKey = key?.matchingKey ?? self.matchingKey
        let bucketingKey = key?.bucketingKey ?? self.bucketingKey

        if let errorInfo = keyValidator.validate(matchingKey: matchingKey, bucketingKey: bucketingKey) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            return nil
        }
        
        let finalKey = Key(matchingKey: matchingKey!, bucketingKey: bucketingKey)
        
        if apiKey?.uppercased() == kApiKeyLocalhost {
            return LocalhostSplitFactory(key: finalKey,
                                         config: config ?? SplitClientConfig(),
                                         bundle: bundle)
        }

        return DefaultSplitFactory(apiKey: apiKey!,
                                   key: finalKey,
                                   config: config ?? SplitClientConfig())
    }
}
