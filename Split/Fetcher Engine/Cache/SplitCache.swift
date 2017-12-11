//
//  SplitCache.swift
//  Split
//
//  Created by Natalia  Stele on 05/12/2017.
//

import Foundation
import SwiftyJSON

public class SplitCache: SplitCacheProtocol {
    
    public static let SPLIT_FILE_PREFIX: String = "SPLITIO.split."
    public static let CHANGE_NUMBER_FILE_PREFIX: String = "SPLITIO.changeNumber"
    var storage: StorageProtocol
    
    init(storage: StorageProtocol) {
        
       self.storage = storage
    }
    
    public func addSplit(splitName: String, split: Split) -> Bool {
        
        let jsonString = split.splitJson?.rawString()
        storage.write(elementId: getSplitId(splitName: splitName), content: jsonString)
        return true
        
    }
    
    public func removeSplit(splitName: String) -> Bool {
        storage.delete(elementId: getSplitId(splitName: splitName))
        return true
    }
    
    public func setChangeNumber(_ changeNumber: Int64) -> Bool {
        
        storage.write(elementId: getChangeNumberId(),content: String(changeNumber))
        return true
        
    }
    
    
    private func getChangeNumberId() -> String {
        
        return SplitCache.CHANGE_NUMBER_FILE_PREFIX
    }

    public func getChangeNumber() -> Int64 {
    
        if let file = storage.read(elementId: getChangeNumberId()), let changeNumber = Int64(file) {
            
            return changeNumber
        }
        
        return -1
    }
    
    public func getSplit(splitName: String) -> Split? {
        
        if let splitString = storage.read(elementId: getSplitId(splitName: splitName)) {
        let json: JSON = JSON(parseJSON: splitString)
        let split = Split(json)
            return split
            
        }
        return nil
    }
    
    public func getAllSplits() -> [Split] {
        
        var splits: [Split] = []
        let names = storage.getAllIds()
        
        for name in names! {
            
            if let split = getSplit(splitName: name) {
                
                splits.append(split)
            }
            
        }
        return splits
    }
    
    public func clear() {
        
    }
    
    
    func getSplitId(splitName: String) -> String {
        
        return SplitCache.SPLIT_FILE_PREFIX + splitName
        
    }

    
}
