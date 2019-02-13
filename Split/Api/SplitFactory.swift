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
        
        /*
         */
        super.init()
        loadLhFile()
    }
    
    func loadLhFile() {
        let fileStorage = FileStorage()
        var fileContent: String? = nil
        
        if let filepath = Bundle.main.path(forResource: "localhost", ofType: "splits") {
            do {
                fileContent = try String(contentsOfFile: filepath, encoding: .utf8)
                print("Localhost file: \(fileContent ?? "NOT FOUND")")
            } catch {
                print("File Read Error for file \(filepath)")
            }
        }
        
        if let content = fileContent {
            let fileName = "localhost.splits"
            let capath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
            let cachesDirectory = URL(fileURLWithPath: capath)
            let path = cachesDirectory.appendingPathComponent(fileName)
            
            fileStorage.write(fileName: fileName, content: content)
            
            print("**************************")
            print("LOCALHOST FILE FOUND WITH PATH: \(path)")
            print("**************************")
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
