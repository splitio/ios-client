//
//  LocalhostSplitFetcher.swift
//  Split
//
//  Created by Javier L. Avrudsky on 14/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

struct LocalhostSplitFetcherConfig {
    var refreshInterval: Int = 10
}

class LocalhostSplitFetcher: SplitFetcher {

    private let refreshInterval: Int
    internal let splits: SyncDictionarySingleWrapper<String, Split>
    private let eventsManager: SplitEventsManager?
    private let fileStorage: FileStorageProtocol
    
    private var pollingManager: PollingManager?
    private var fileName: String!
    private var fileParser: LocalhostSplitsParser!
    
    
    init(fileStorage: FileStorageProtocol, config: LocalhostSplitFetcherConfig = LocalhostSplitFetcherConfig(), eventsManager: SplitEventsManager? = nil, splitsFileName: String) {
        self.fileName = splitsFileName
        self.fileStorage = fileStorage
        self.refreshInterval = config.refreshInterval
        self.splits = SyncDictionarySingleWrapper()
        self.eventsManager = eventsManager
        self.fileParser = getParser()
        loadFile()
        logFileInfo()
        eventsManager?.notifyInternalEvent(.mySegmentsAreReady)
        eventsManager?.notifyInternalEvent(.splitsAreReady)
        if refreshInterval > 0 {
            self.pollingManager = createPollingManager()
            pollingManager?.start()
        }
    }
    
    func forceRefresh() {
        loadFile()
    }
    
    func fetch(splitName: String) -> Split? {
        return splits.value(forKey: splitName)
    }
    
    func fetchAll() -> [Split]? {
        return splits.all.values.map( { $0 })
    }
    
    private func createPollingManager() -> PollingManager {
        var config = PollingManagerConfig()
        config.firstPollWindow = 1
        config.rate = refreshInterval
        
        return PollingManager(
            dispatchGroup: nil,
            config: config,
            triggerAction: {[weak self] in
                if let strongSelf = self {
                    strongSelf.loadFile()
                }
            }
        )
    }
    
    private func loadFile() {
        if let content = fileStorage.read(fileName: fileName), !content.isEmpty {
            let loadedSplits = fileParser.parseContent(content)
            splits.setValues(loadedSplits)
        }
    }
    
    private func getParser() -> LocalhostSplitsParser {
        if fileName.contains(".yaml") || fileName.contains(".yml") {
            return YamlLocalhostSplitsParser()
        }
        return SpaceDelimitedLocalhostSplitsParser()
    }
    
    private func logFileInfo() {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let cacheDirectory = URL(fileURLWithPath: cachePath)
        let path = cacheDirectory.appendingPathComponent(fileName)
        Logger.d("Localhost file path: \(path)")
    }
}
