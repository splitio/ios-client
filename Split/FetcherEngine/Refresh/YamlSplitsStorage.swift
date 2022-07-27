//
//  YamlSplitsStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 05/01/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

struct YamlSplitStorageConfig {
    var refreshInterval: Int = 10
}

class LocalhostSplitsStorage: SplitsStorage {

    var changeNumber: Int64 = -1
    var updateTimestamp: Int64 = 1
    var splitsFilterQueryString: String = ""

    typealias FileInfo = (name: String, type: String)
    private let refreshInterval: Int
    private let eventsManager: SplitEventsManager
    private let fileStorage: FileStorageProtocol
    private var taskExecutor: PeriodicTaskExecutor?
    private var fileParser: LocalhostSplitsParser!
    private let supportedExtensions = ["yaml", "yml", "splits"]
    private let fileName: String
    private let inMemorySplits = ConcurrentDictionary<String, Split>()
    private let dataQueue = DispatchQueue(label: "Split yaml storage queue", attributes: .concurrent)

    init(fileStorage: FileStorageProtocol,
         config: YamlSplitStorageConfig = YamlSplitStorageConfig(),
         eventsManager: SplitEventsManager, dataFolderName: String,
         splitsFileName: String, bundle: Bundle) {

        self.fileName = splitsFileName
        self.fileStorage = fileStorage
        self.refreshInterval = config.refreshInterval
        self.eventsManager = eventsManager

        initSdk(bundle: bundle, dataFolderName: dataFolderName)
    }

    func loadLocal() {
        dataQueue.async(flags: .barrier) {
            self.loadFile(name: self.fileName)
            Logger.i("Localhost splits updated")
        }
    }

    func get(name: String) -> Split? {
        var split: Split?
        dataQueue.sync {
            split = inMemorySplits.value(forKey: name)
        }
        return split
    }

    func getMany(splits: [String]) -> [String: Split] {
        var splitMap: [String: Split]?
        dataQueue.sync {
            let names = Set(splits)
            splitMap = self.inMemorySplits.all.filter { return names.contains($0.key) }
        }
        return splitMap ?? [String: Split]()
    }

    func getAll() -> [String: Split] {
        var splitMap: [String: Split]?
        dataQueue.sync {
            splitMap = self.inMemorySplits.all
        }
        return splitMap ?? [String: Split]()
    }

    func update(splitChange: ProcessedSplitChange) {
    }

    func update(filterQueryString: String) {
    }

    func updateWithoutChecks(split: Split) {
    }

    func isValidTrafficType(name: String) -> Bool {
        return true
    }

    func clear() {
        dataQueue.async(flags: .barrier) {
            self.inMemorySplits.removeAll()
        }
    }

    func getCount() -> Int {
        dataQueue.sync {
            return inMemorySplits.count
        }
    }

    func start() {
        taskExecutor?.start()
    }

    func stop() {
        taskExecutor?.stop()
    }

    func destroy() {
        inMemorySplits.removeAll()
    }

    private func createTaskExecutor() -> PeriodicTaskExecutor {
        var config = PeriodicTaskExecutorConfig()
        config.firstExecutionWindow = refreshInterval
        config.rate = refreshInterval
        return PeriodicTaskExecutor(
            dispatchGroup: nil,
            config: config,
            triggerAction: {[weak self] in
                if let self = self {
                    self.loadLocal()
                }
            }
        )
    }

    private func parser(for type: String) -> LocalhostSplitsParser {
        if type == "yaml" || type == "yml" {
            return YamlLocalhostSplitsParser()
        }
        Logger.w("""
                Localhost mode: .split mocks will be deprecated soon in favor of YAML files,
                which provide more targeting power. Take a look in our documentation.
                """)
        return SpaceDelimitedLocalhostSplitsParser()
    }

    private func logFileInfo(dataFolder: String, name: String) {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let cacheDirectory = URL(fileURLWithPath: cachePath)
        let path = cacheDirectory.appendingPathComponent(dataFolder).appendingPathComponent(name)
        Logger.i("Localhost file path: \(path)")
    }

    private func splitFileName(_ fileName: String) -> FileInfo? {
        if let dotIndex = fileName.lastIndex(of: ".") {
            let name = String(fileName.prefix(upTo: dotIndex))
            let type = String(fileName.suffix(from: fileName.index(after: dotIndex)))
            if type != "", name != "" {
                return (name: name, type: type)
            }
        }
        return nil
    }

    private func isSupportedExtensionType(_ type: String) -> Bool {
        return supportedExtensions.filter({ $0 == type.lowercased() }).count == 1
    }

    private func validateAndCopyFile(bundle: Bundle) -> FileInfo? {
        guard let fileInfo = splitFileName(fileName) else {
            Logger.e("""
                Localhost file name \(fileName) has not the correct format.
                It should be similar to 'name.yaml', 'name.yml'
                """)
            return nil
        }

        if !isSupportedExtensionType(fileInfo.type) {
            Logger.e("Localhost file extension \(fileInfo.type) is not supported. It should be '.yaml', '.yml'")
            return nil
        }

        if !LocalhostFileCopier(bundle: bundle).copySourceFile(name: fileInfo.name,
                                                               type: fileInfo.type,
                                                               fileStorage: fileStorage) {
            Logger.e("Localhost file name \(fileName) not found. Please check name.")
            return nil
        }
        return fileInfo
    }

    private func initSdk(bundle: Bundle, dataFolderName: String) {
        dataQueue.async(flags: .barrier) {
            self.initSdkSync(bundle: bundle, dataFolderName: dataFolderName)

        }
    }

    // Must be called from initSdk. Just to avoid using self many times
    private func initSdkSync(bundle: Bundle, dataFolderName: String) {
        guard let fileInfo = validateAndCopyFile(bundle: bundle) else {
            triggerSdkTimeout()
            return
        }

        fileParser = parser(for: fileInfo.type)
        if !loadFile(name: fileName) {
            triggerSdkTimeout()
            Logger.e("Localhost file \(fileName) not found or empty.")
            return
        }

        logFileInfo(dataFolder: dataFolderName, name: fileName)
        triggerSdkReady()
        startPeriodicRefresh()
    }

    // Must be called from initSdk. Just to avoid using self many times
    @discardableResult
    private func loadFile(name: String) -> Bool {

        inMemorySplits.removeAll()
        guard let content = fileStorage.read(fileName: name), let parser = self.fileParser else {
            return false
        }

        let loadedSplits = parser.parseContent(content)

        if loadedSplits.count < 1 {
            return false
        }

        inMemorySplits.setValues(loadedSplits)
        return true
    }

    private func triggerSdkTimeout() {
        eventsManager.notifyInternalEvent(SplitInternalEvent.sdkReadyTimeoutReached)
    }

    private func triggerSdkReady() {
        eventsManager.notifyInternalEvent(.mySegmentsUpdated)
        eventsManager.notifyInternalEvent(.splitsUpdated)
    }

    private func startPeriodicRefresh() {
        if refreshInterval > 0 {
            self.taskExecutor = createTaskExecutor()
            self.start()
        }
    }
}

class LocalhostFileCopier {
    var bundle: Bundle!

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    func copySourceFile(name: String, type: String, fileStorage: FileStorageProtocol) -> Bool {

        guard let fileContent = loadInitialFile(name: name, type: type) else {
            return false
        }
        fileStorage.write(fileName: "\(name).\(type)", content: fileContent)
        return true
    }

    private func loadInitialFile(name fileName: String, type fileType: String) -> String? {
        var fileContent: String?
        if let filepath = bundle.path(forResource: fileName, ofType: fileType) {
            do {
                fileContent = try String(contentsOfFile: filepath, encoding: .utf8)
            } catch {
                Logger.e("Could not load localhost file: \(filepath)")
            }
        }
        return fileContent
    }
}
