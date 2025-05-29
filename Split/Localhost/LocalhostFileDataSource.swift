//
//  FeatureFlagsFileLoader.swift
//  Split
//
//  Created by Javier Avrudsky on 03/01/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

protocol LocalhostDataSource: AnyObject {
    typealias IncomingDataHandler = ([String: Split]?) -> Void
    var loadHandler: IncomingDataHandler? { get set }
    func start()
    func stop()
}

struct FeatureFlagsFileLoaderConfig {
    var refreshInterval: Int = ServiceConstants.defaultLocalhostRefreshRate
}

enum LocalhostFile {
    case yaml
    case splits

    static var yamlExtensions: [String] {
        ["yaml", "yml"]
    }

    static var splitExtensions: [String] {
        ["splits"]
    }

    static var extensions: [String] {
        yamlExtensions + splitExtensions
    }
}

class FeatureFlagsFileLoader: LocalhostDataSource {
    var loadHandler: LocalhostDataSource.IncomingDataHandler?

    typealias FileInfo = (name: String, type: String)
    private let refreshInterval: Int

    private let fileStorage: FileStorage
    private var taskExecutor: PeriodicTaskExecutor?
    private var fileParser: LocalhostSplitsParser?
    private let fileName: String
    private var lastContent = ""
    private let dataQueue = DispatchQueue(
        label: "split-yaml-storage",
        attributes: .concurrent)

    init(
        fileStorage: FileStorage,
        config: FeatureFlagsFileLoaderConfig = FeatureFlagsFileLoaderConfig(),
        dataFolderName: String,
        splitsFileName: String,
        bundle: Bundle) throws {
        self.fileName = splitsFileName
        self.fileStorage = fileStorage
        self.refreshInterval = Self.sanitizeRefreshInterval(config.refreshInterval)
        if !setup(bundle: bundle, dataFolderName: dataFolderName) {
            throw GenericError.unknown(message: "Could setup localhost file loader.")
        }
        self.taskExecutor = createTaskExecutor()
    }

    func start() {
        taskExecutor?.start()
    }

    func stop() {
        taskExecutor?.stop()
    }

    private func setup(bundle: Bundle, dataFolderName: String) -> Bool {
        guard let fileInfo = validateAndCopyFile(bundle: bundle) else {
            Logger.e("Could not load localhost file.")
            return false
        }

        fileParser = LocalhostParserProvider.parser(for: fileInfo.type)
        logFileInfo(dataFolder: dataFolderName, name: fileName)

        return true
    }

    private static func sanitizeRefreshInterval(_ refreshInterval: Int) -> Int {
        return refreshInterval > 0 ? refreshInterval : ServiceConstants.defaultLocalhostRefreshRate
    }

    private func createTaskExecutor() -> PeriodicTaskExecutor {
        var config = PeriodicTaskExecutorConfig()
        config.firstExecutionWindow = refreshInterval
        config.rate = refreshInterval
        return PeriodicTaskExecutor(
            dispatchGroup: nil,
            config: config,
            triggerAction: { [weak self] in
                if let self = self {
                    self.loadHandler?(self.loadFile())
                }
            })
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
        return LocalhostFile.extensions.filter { $0 == type.lowercased() }.count == 1
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

        if !FileUtil.copySourceFile(
            name: fileInfo.name,
            type: fileInfo.type,
            fileStorage: fileStorage,
            bundle: bundle) {
            Logger.e("Localhost file name \(fileName) not found. Please check name.")
            return nil
        }
        return fileInfo
    }

    private func loadFile() -> [String: Split]? {
        let name = fileName
        guard let content = fileStorage.read(fileName: name), let parser = fileParser else {
            return nil
        }

        if lastContent == content {
            return nil
        }
        lastContent = content
        return parser.parseContent(content)
    }
}
