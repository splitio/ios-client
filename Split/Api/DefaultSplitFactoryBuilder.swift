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

    private var matchingKey: String?
    private var bucketingKey: String?
    private var bundle: Bundle = Bundle.main
    private let kApiKeyLocalhost = "LOCALHOST"
    private let keyValidator: KeyValidator
    private let apiKeyValidator: ApiKeyValidator
    var validationLogger: ValidationMessageLogger
    private let validationTag = "factory instantiation"
    private var params: SplitFactoryParams = SplitFactoryParams()

    private let moreThanOneFactoryMessage = """
    You already have an instance of the Split factory. Make sure you definitely want this
        additional instance. We recommend keeping only one instance of the factory at all times
        (Singleton pattern) and reusing it throughout your application.
    """

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
        params.apiKey = apiKey
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
        params.key = key
        return self
    }

    public func setConfig(_ config: SplitClientConfig) -> SplitFactoryBuilder {
        params.config = config
        return self
    }

    func setBundle(_ bundle: Bundle) -> SplitFactoryBuilder {
        self.bundle = bundle
        return self
    }

    func setHttpClient(_ httpClient: HttpClient) -> SplitFactoryBuilder {
        params.httpClient = httpClient
        return self
    }

    func setReachabilityChecker(_ checker: HostReachabilityChecker) -> SplitFactoryBuilder {
        params.reachabilityChecker = checker
        return self
    }

    func setTestDatabase(_ database: SplitDatabase) -> SplitFactoryBuilder {
        params.testDatabase = database
        return self
    }

    func setNotificationHelper(_ notificationHelper: NotificationHelper) -> SplitFactoryBuilder {
        params.notificationHelper = notificationHelper
        return self
    }

    func setTelemetryStorage(_ telemetryStorage: TelemetryStorage) -> SplitFactoryBuilder {
        params.telemetryStorage = telemetryStorage
        return self
    }

    public func build() -> SplitFactory? {

        var telemetryStorage: TelemetryStorage?
        if params.config.isTelemetryEnabled {
            telemetryStorage = params.telemetryStorage ?? InMemoryTelemetryStorage()
            params.telemetryStorage = telemetryStorage
            params.initStopwatch.start(unit: .milliseconds)
        }

        if let errorInfo = apiKeyValidator.validate(apiKey: params.apiKey) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            return nil
        }

        let matchingKey = self.matchingKey ?? params.key.matchingKey
        let bucketingKey = self.bucketingKey ?? params.key.bucketingKey

        if let errorInfo = keyValidator.validate(matchingKey: matchingKey, bucketingKey: bucketingKey) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            return nil
        }

        var factoryCount = DefaultSplitFactoryBuilder.factoryMonitor.instanceCount(for: params.apiKey)
        if factoryCount > 0 {
            let errorInfo = ValidationErrorInfo(error: ValidationError.some,
                                                message: apiKeyFactoryCountMessage(factoryCount))
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)

        } else if DefaultSplitFactoryBuilder.factoryMonitor.allCount > 0 {
            let errorInfo = ValidationErrorInfo(error: ValidationError.some,
                                                message: moreThanOneFactoryMessage)
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
        }

        params.key = Key(matchingKey: matchingKey, bucketingKey: bucketingKey)

        var factory: SplitFactory?
        if params.apiKey.uppercased() == kApiKeyLocalhost {
            factory = LocalhostSplitFactory(key: params.key,
                                            config: params.config,
                                            bundle: bundle)
        } else {
            do {
                factory = try DefaultSplitFactory(params)
            } catch ComponentError.notFound(let name) {
                Logger.e("Component was not created properly: \(name)")
            } catch {
                Logger.e("Error: \(error)")
            }
        }

        DefaultSplitFactoryBuilder.factoryMonitor.register(instance: factory, for: params.apiKey)
        factoryCount = DefaultSplitFactoryBuilder.factoryMonitor.instanceCount(for: params.apiKey)
        let activeCount = DefaultSplitFactoryBuilder.factoryMonitor.activeCount()
        telemetryStorage?.recordFactories(active: activeCount, redundant: factoryCount - 1)

        return factory
    }

    private func apiKeyFactoryCountMessage(_ factoryCount: Int) -> String {
        return "You already have \(factoryCount) \(factoryCount == 1 ? "factory" : "factories") with this " +
            "API Key. We recommend keeping only one instance of the factory at all times " +
            "(Singleton pattern) and reusing it throughout your application."
    }
}

struct SplitFactoryParams {
    var notificationHelper: NotificationHelper?
    var testDatabase: SplitDatabase?
    var reachabilityChecker: HostReachabilityChecker?
    var httpClient: HttpClient?
    var apiKey: String = ""
    var key: Key = Key(matchingKey: "")
    var config: SplitClientConfig = SplitClientConfig()
    var telemetryStorage: TelemetryStorage?
    var initStopwatch: Stopwatch = Stopwatch()
}
