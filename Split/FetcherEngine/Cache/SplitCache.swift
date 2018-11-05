//
//  SplitCache.swift
//  Split
//
//  Created by Natalia  Stele on 05/12/2017.
//

import Foundation

public class SplitCache: SplitCacheProtocol {
    
    public static let SPLIT_FILE_PREFIX: String = "SPLITIO.split."
    public static let CHANGE_NUMBER_FILE_PREFIX: String = "SPLITIO.changeNumber"
    private let kClassName = String(describing: SplitCache.self)
    
    var storage: StorageProtocol
    var inMemoryCache: InMemorySplitCache
    
    init(storage: StorageProtocol) {
        
        self.storage = storage
        
        var splits: [String:Split] = [:]
        if let names = storage.getAllIds() {
            for name in names {
                var split: Split? = nil
                if let splitString = storage.read(elementId: name) {
                    do {
                        split = try Json.encodeFrom(json: splitString, to: Split.self)
                    } catch {
                        // TODO: Improve this code!!!
                    }
                }
                
                if let split = split, split.isValid {
                    splits[split.name!] = split
                }
            }
        }
        
        var changeNumber = Int64(-1)
        if let file = storage.read(elementId: SplitCache.CHANGE_NUMBER_FILE_PREFIX), let changeNb = Int64(file) {
            changeNumber = changeNb
        }
        inMemoryCache = InMemorySplitCache(splits: splits, changeNumber: changeNumber)
    }
    
    public func addSplit(splitName: String, split: Split) -> Bool {
        do {
            let jsonString = try JSON.encodeToJson(split)
            storage.write(elementId: getSplitId(splitName: splitName), content: jsonString)
            _ = inMemoryCache.addSplit(splitName: splitName, split: split)
        } catch {
            Logger.e("addSplit: Error parsing split to Json", kClassName)
        }
        return true
    }
    
    public func removeSplit(splitName: String) -> Bool {
        storage.delete(elementId: getSplitId(splitName: splitName))
        _ = inMemoryCache.removeSplit(splitName: splitName)
        return true
    }
    
    public func setChangeNumber(_ changeNumber: Int64) -> Bool {
        storage.write(elementId: getChangeNumberId(),content: String(changeNumber))
        _ = inMemoryCache.setChangeNumber(changeNumber)
        return true
    }
    
    private func getChangeNumberId() -> String {
        return SplitCache.CHANGE_NUMBER_FILE_PREFIX
    }
    
    public func getChangeNumber() -> Int64 {
        return inMemoryCache.getChangeNumber()
    }
    
    public func getSplit(splitName: String) -> Split? {
        return inMemoryCache.getSplit(splitName: splitName)
    }
    
    public func getAllSplits() -> [Split] {
        return inMemoryCache.getAllSplits()
    }
    
    public func clear() {
    }
    
    func getSplitId(splitName: String) -> String {
        return SplitCache.SPLIT_FILE_PREFIX + splitName
    }
}
