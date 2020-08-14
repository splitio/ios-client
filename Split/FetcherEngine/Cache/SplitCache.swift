//
//  SplitCache.swift
//  Split
//
//  Created by Natalia  Stele on 05/12/2017.
//
//  Refactored by Javier Avrudsky on 11/08/2018

import Foundation

/// ** SplitCache **
/// Handles Splits Cache by loading them from disk
/// into memory when the class is instantiated.
/// In memory splits are updated each time new information is retrieved
/// from the server and it is saved to disk when application goes to background.

class SplitCache: SplitCacheProtocol {

    private struct SplitsFile: Codable {
        var splits: [String: Split]
        var changeNumber: Int64
        var timestamp: Int? = 0
    }

    let kSplitsFileName: String = "SPLITIO.splits"
    private let fileStorage: FileStorageProtocol
    private var inMemoryCache: InMemorySplitCache = InMemorySplitCache(splits: [String: Split](), changeNumber: -1, timestamp: 0)

    init(fileStorage: FileStorageProtocol) {
        self.fileStorage = fileStorage
        if let splitsFile = loadSplitFile() {
            self.inMemoryCache = buildInMemoryCache(splitsFile: splitsFile)
        }
        NotificationHelper.instance.addObserver(for: AppNotification.didEnterBackground) {
            DispatchQueue.global().async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.saveSplits()
            }
        }
    }

    func addSplit(splitName: String, split: Split) {
        inMemoryCache.addSplit(splitName: splitName, split: split)
    }

    func setChangeNumber(_ changeNumber: Int64) {
        inMemoryCache.setChangeNumber(changeNumber)
    }

    func getChangeNumber() -> Int64 {
        return inMemoryCache.getChangeNumber()
    }

    func getSplit(splitName: String) -> Split? {
        return inMemoryCache.getSplit(splitName: splitName)
    }

    func getAllSplits() -> [Split] {
        return inMemoryCache.getAllSplits()
    }

    func getSplits() -> [String: Split] {
        return inMemoryCache.getSplits()
    }

    func exists(trafficType: String) -> Bool {
        return inMemoryCache.exists(trafficType: trafficType)
    }

    func clear() {
        inMemoryCache.clear()
        inMemoryCache.setChangeNumber(-1)
        fileStorage.delete(fileName: kSplitsFileName)
    }

    func getTimestamp() -> Int {
        return inMemoryCache.getTimestamp()
    }

    func setTimestamp(timestamp: Int) {
        inMemoryCache.setTimestamp(timestamp: timestamp)
    }
}

// MARK: Private
extension SplitCache {
    private func buildInMemoryCache(splitsFile: SplitsFile) -> InMemorySplitCache {
        return InMemorySplitCache(splits: splitsFile.splits,
                                  changeNumber: splitsFile.changeNumber,
                                  timestamp: splitsFile.timestamp)
    }

    private func loadSplitFile() -> SplitsFile? {
        guard let jsonContent = fileStorage.read(fileName: kSplitsFileName) else {
            return nil
        }
        do {
            return try Json.encodeFrom(json: jsonContent, to: SplitsFile.self)
        } catch {
            Logger.e("Error while loading Splits from disk")
        }
        return nil
    }

    private func saveSplits() {
        let splitsFile = SplitsFile(splits: getSplits(), changeNumber: getChangeNumber(), timestamp: getTimestamp())
        do {
            let jsonSplits = try Json.encodeToJson(splitsFile)
            fileStorage.write(fileName: kSplitsFileName, content: jsonSplits)
        } catch {
            Logger.e("Could not save splits on disk")
        }
    }
}
