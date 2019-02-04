//
//  SplitFactory.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

public class SplitFactory: NSObject, SplitFactoryProtocol {
    
    let _client: SplitClientProtocol
    let _manager: SplitManagerProtocol
    
    @objc(initWithApiKey:key:config:) public init(apiKey: String, key: Key, config: SplitClientConfig) {
        HttpSessionConfig.default.connectionTimeOut = TimeInterval(config.connectionTimeout)
        MetricManagerConfig.default.pushRateInSeconds = config.metricsPushRate
    
        config.apiKey = apiKey
        let splitCache = SplitCache()
        let splitFetcher: SplitFetcher = LocalSplitFetcher(splitCache: splitCache)
        
        _client = SplitClient(config: config, key: key, splitCache: splitCache)
        _manager = SplitManager(splitFetcher: splitFetcher)
        
        
        if let filepath = Bundle.main.path(forResource: "localhost", ofType: "splits") {
            do {
                let fileContent = try String(contentsOfFile: filepath, encoding: .utf8)
                print("Localhost file: \(fileContent)")
            } catch {
                print("File Read Error for file \(filepath)")
            }
        }
    }

    public func client() -> SplitClientProtocol {
        return _client
    }
    
    public func manager() -> SplitManagerProtocol {
        return _manager
    }
    
    public func version() -> String {
        return Version.toString()
    }
    
    func openFile() {
        if let filepath = Bundle.main.path(forResource: "localhost", ofType: "splits") {
            do {
                let fileContent = try String(contentsOfFile: filepath, encoding: .utf8)
                print("Localhost file: \(fileContent)")
            } catch {
                print("File Read Error for file \(filepath)")
            }
        }
    }
    
    
}
