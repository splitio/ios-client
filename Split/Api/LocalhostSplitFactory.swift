//
//  LocalhostSplitFactory.swift
//  Split
//
//  Created by Javier L. Avrudsky on 14/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

///
/// SplitFactory implementation for Localhost mode
///
/// This mode is intended to use during development.
/// Check LocalhostSplitClient class for more information
///  - seealso:
/// [Split iOS SDK](https://docs.split.io/docs/ios-sdk-overview#section-localhost)
///
public class LocalhostSplitFactory: NSObject, SplitFactory {
    
    private let localhostClient: SplitClient
    private let localhostManager: SplitManager
    private let eventsManager: SplitEventsManager
    private let kDefaultFileName = "localhost"
    private var fileName: String
    
    public var client: SplitClient {
        return localhostClient
    }
    
    public var manager: SplitManager {
        return localhostManager
    }
    
    public var version: String {
        return Version.toString()
    }
    
    init(key: Key, config: SplitClientConfig, bundle: Bundle, splitsFileName: String? = nil) {
        fileName = kDefaultFileName
        if let splitsFileName = splitsFileName {
            fileName = splitsFileName
        }
        HttpSessionConfig.default.connectionTimeOut = TimeInterval(config.connectionTimeout)
        MetricManagerConfig.default.pushRateInSeconds = config.metricsPushRate
        let fileStorage = FileStorage(dataFolderName: DataFolderFactory().createFrom(apiKey: config.apiKey) ?? config.defaultDataFolder)
        let fileCopier = LocalhostFileCopier(bundle: bundle)
        let splitsFileName = fileCopier.copySourceFile(fileName: fileName, fileStorage: fileStorage)
        eventsManager = SplitEventsManager(config: config)
        eventsManager.start()
        
        let splitFetcher: SplitFetcher = LocalhostSplitFetcher(fileStorage: fileStorage, eventsManager: eventsManager, splitsFileName: splitsFileName)
        localhostClient = LocalhostSplitClient(key:key, splitFetcher: splitFetcher, eventsManager: eventsManager)
        localhostManager = DefaultSplitManager(splitFetcher: splitFetcher)
        eventsManager.getExecutorResources().setClient(client: localhostClient)
    }
    
}

class LocalhostFileCopier {
    var bundle: Bundle!
    
    init(bundle: Bundle) {
        self.bundle = bundle
    }
    
    func copySourceFile(fileName: String, fileStorage: FileStorageProtocol) -> String {
        var fileContent: String? = nil
        var fileType = "yaml"
        var fullFileName = "\(fileName).\(fileType)"
        if let content = loadInitialFile(name: fileName, type: fileType) {
            fileContent = content
        }
        
        if fileContent == nil {
            fileType = "yml"
            if let content = loadInitialFile(name: fileName, type: fileType) {
                fileContent = content
                fullFileName = "\(fileName).\(fileType)"
            }
        }
        
        if fileContent == nil {
            fileType = "splits"
            if let content = loadInitialFile(name: fileName, type: fileType) {
                fileContent = content
                fullFileName = "\(fileName).\(fileType)"
                Logger.w("Localhost mode: .split mocks will be deprecated soon in favor of YAML files, which provide more targeting power. Take a look in our documentation.")
            }
        }
        
        if fileContent == nil {
            Logger.w("Localhost mode: file or content not found. An empty yaml file will be created")
        }
        fileStorage.write(fileName: fullFileName, content: fileContent ?? "")
        return fullFileName
    }
    
    private func loadInitialFile(name fileName: String, type fileType: String) -> String? {
        var fileContent: String? = nil
        if let filepath = bundle.path(forResource: fileName, ofType: fileType) {
            do {
                fileContent = try String(contentsOfFile: filepath, encoding: .utf8)
            } catch {
                Logger.e("File Read Error for file \(filepath)")
            }
        }
        return fileContent
    }
}
