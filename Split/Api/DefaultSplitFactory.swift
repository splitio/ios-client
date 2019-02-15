//
//  SplitFactory.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

/**
 Default implementation of SplitManager protocol
 */
public class DefaultSplitFactory: NSObject, SplitFactory {
    
    private let defaultClient: SplitClient
    private let defaultManager: SplitManager
    
    public var client: SplitClient {
        return defaultClient
    }
    
    public var manager: SplitManager {
        return defaultManager
    }
    
    public var version: String {
        return Version.toString()
    }
    
    init(apiKey: String, key: Key, config: SplitClientConfig) {
        HttpSessionConfig.default.connectionTimeOut = TimeInterval(config.connectionTimeout)
        MetricManagerConfig.default.pushRateInSeconds = config.metricsPushRate
    
        config.apiKey = apiKey
        let splitCache = SplitCache()
        let splitFetcher: SplitFetcher = LocalSplitFetcher(splitCache: splitCache)
        
        defaultClient = DefaultSplitClient(config: config, key: key, splitCache: splitCache)
        defaultManager = DefaultSplitManager(splitFetcher: splitFetcher)
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
