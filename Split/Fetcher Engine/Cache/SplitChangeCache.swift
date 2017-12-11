//
//  SplitChangeCache.swift
//  Split
//
//  Created by Natalia  Stele on 06/12/2017.


import Foundation
import SwiftyJSON

public class  SplitChangeCache: SplitChangeCacheProtocol {
    
    public static let SPLIT_FILE_PREFIX: String = "SPLITIO.split."
    public static let CHANGE_NUMBER_FILE_PREFIX: String = "SPLITIO.changeNumber"
    var splitCache: SplitCacheProtocol?
    
    //------------------------------------------------------------------------------------------------------------------
    init(storage: StorageProtocol) {
        
        self.splitCache = SplitCache(storage: storage)
        
    }
    //------------------------------------------------------------------------------------------------------------------
    public func addChange(splitChange: SplitChange) -> Bool {
        
        if splitCache == nil { return false }
        
        var result = true
        
        let _ = self.splitCache?.setChangeNumber(splitChange.till!)
     
        
        for split in splitChange.splits! {
            
            result = result && (splitCache?.addSplit(splitName: split.name!, split: split))!
            
        }
        
        return result
        
    }
    //------------------------------------------------------------------------------------------------------------------
    public func getChanges(since: Int64) -> SplitChange? {
        
        let changeNumber = splitCache?.getChangeNumber()
        
        let splitChange: SplitChange = SplitChange()
        
        splitChange.since = changeNumber
        splitChange.till = changeNumber
        splitChange.splits = []
        
        if splitChange.since! == -1  || splitChange.since! < splitChange.till! {
            
            splitChange.splits = splitCache?.getAllSplits()
            
        }
        
        return splitChange
        
    }
    //------------------------------------------------------------------------------------------------------------------
}
