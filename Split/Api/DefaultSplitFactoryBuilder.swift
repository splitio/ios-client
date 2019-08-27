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
    var validationLogger: ValidationMessageLogger
    private let validationTag = "factory instantiation"

    private static let  factoryMonitor: FactoryMonitor = {
        return DefaultFactoryMonitor()
    }()

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

        let factoryCount = DefaultSplitFactoryBuilder.factoryMonitor.instanceCount(for: apiKey!)
        if factoryCount > 0 {
            let errorInfo = ValidationErrorInfo(
                error: ValidationError.some,
                message: "You already have \(factoryCount) \(factoryCount == 1 ? "factory" : "factories") with this " +
                "API Key. We recommend keeping only one instance of the factory at all times (Singleton pattern) and " +
                "reusing it throughout your application.")
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)

        } else if DefaultSplitFactoryBuilder.factoryMonitor.allCount > 0 {
            let errorInfo = ValidationErrorInfo(
                error: ValidationError.some,
                message: "You already have an instance of the Split factory. Make sure you definitely want this " +
                "additional instance. We recommend keeping only one instance of the factory at all times " +
                "(Singleton pattern) and reusing it throughout your application.")
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
        }

        let finalKey = Key(matchingKey: matchingKey!, bucketingKey: bucketingKey)

        var factory: SplitFactory!
        if apiKey?.uppercased() == kApiKeyLocalhost {
            factory = LocalhostSplitFactory(key: finalKey,
                                            config: config ?? SplitClientConfig(),
                                            bundle: bundle)
        } else {
            factory = DefaultSplitFactory(apiKey: apiKey!,
                                   key: finalKey,
                                   config: config ?? SplitClientConfig())
        }

        DefaultSplitFactoryBuilder.factoryMonitor.register(instance: factory, for: apiKey!)
        return factory
    }
}
