//
//  SplitCache.swift
//  Split
//
//  Created by Natalia  Stele on 05/12/2017.
//
//  Refactored by Javier Avrudsky on 11/08/2018

import Foundation

class SplitCache: SplitCacheProtocol {
    
    private struct SplitsFile: Codable {
        var splits: [String: Split]
        var changeNumber: Int64
    }

    let kSplitsFileName: String = "SPLITIO.split.splitsFile"
    var fileStorage: FileStorageProtocol
    var inMemoryCache: InMemorySplitCache!
    
    convenience init(){
        self.init(fileStorage: FileStorage())
    }
    
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
    
    func removeSplit(splitName: String) {
        inMemoryCache.removeSplit(splitName: splitName)
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
    
    func getSplits() -> [String : Split] {
        return inMemoryCache.getSplits()
    }
    
    func clear() {
    }
}

// MARK: Private
extension SplitCache {
    private func initialInMemoryCache() -> InMemorySplitCache {
        var inMemoryCache = InMemorySplitCache(splits: [String: Split]())
        guard let jsonContent = fileStorage.read(fileName: kSplitsFileName) else {
            return inMemoryCache
        }
        do {
            let splitsFile = try Json.encodeFrom(json: jsonContent, to: SplitsFile.self)
            inMemoryCache = InMemorySplitCache(splits: splitsFile.splits, changeNumber: splitsFile.changeNumber)
        } catch {
            Logger.e("Error while loading Splits from disk")
        }
        return inMemoryCache
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
