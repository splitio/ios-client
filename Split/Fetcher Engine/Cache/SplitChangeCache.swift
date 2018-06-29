//
//  SplitChangeCache.swift
//  Split
//
//  Created by Natalia  Stele on 06/12/2017.


import Foundation

public class  SplitChangeCache: SplitChangeCacheProtocol {
    
    private let _queue = DispatchQueue(label: "io.Split.FetcherEngine.Cache.SplitChangeCache.SyncQueue")
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
        _queue.sync {
            
            let _ = self.splitCache?.setChangeNumber(splitChange.till!)
            
            for split in splitChange.splits! {
                result = result && (self.splitCache?.addSplit(splitName: split.name!, split: split))!
            }
        }
        
        return result
        
    }
    //------------------------------------------------------------------------------------------------------------------
    public func getChanges(since: Int64) -> SplitChange? {
        
        let splitChange: SplitChange = SplitChange()
        
        _queue.sync {
            let changeNumber = self.splitCache?.getChangeNumber()
            
            splitChange.since = changeNumber
            splitChange.till = changeNumber
            splitChange.splits = []
            
            if splitChange.since! == -1  || splitChange.since! < splitChange.till! {
                splitChange.splits = self.splitCache?.getAllSplits()
            }
        }
        
        return splitChange
        
    }
    //------------------------------------------------------------------------------------------------------------------
}
