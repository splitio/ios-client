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
    }

    let kSplitsFileName: String = "SPLITIO.splits"
    let fileStorage: FileStorageProtocol
    var inMemoryCache: InMemorySplitCache!

    init(fileStorage: FileStorageProtocol) {
        self.fileStorage = fileStorage
        self.inMemoryCache = initialInMemoryCache()
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
}

// MARK: Private
extension SplitCache {
    private func initialInMemoryCache() -> InMemorySplitCache {
        let emptySplitCache: (() -> InMemorySplitCache) = {
            return InMemorySplitCache(splits: [String: Split]())
        }

        guard let jsonContent = fileStorage.read(fileName: kSplitsFileName) else {
            return emptySplitCache()
        }
        do {
            let splitsFile = try Json.encodeFrom(json: jsonContent, to: SplitsFile.self)
            return InMemorySplitCache(splits: splitsFile.splits, changeNumber: splitsFile.changeNumber)
        } catch {
            Logger.e("Error while loading Splits from disk")
        }
        return emptySplitCache()
    }

    private func saveSplits() {
        let splitsFile = SplitsFile(splits: getSplits(), changeNumber: getChangeNumber())
        do {
            let jsonSplits = try Json.encodeToJson(splitsFile)
            fileStorage.write(fileName: kSplitsFileName, content: jsonSplits)
        } catch {
            Logger.e("Could not save splits on disk")
        }
    }
}
