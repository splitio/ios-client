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
    
    init(splitCache: SplitCacheProtocol) {
        self.splitCache = splitCache
    }
    
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
    
    public func getChanges(since: Int64) -> SplitChange? {
        
        guard let splitCache = self.splitCache else {
            return nil
        }

        var splitChange: SplitChange? = nil
        _queue.sync {
            let changeNumber = splitCache.getChangeNumber()
            if changeNumber != -1 {
                splitChange = SplitChange()
                splitChange!.since = since
                splitChange!.till = changeNumber
                splitChange!.splits = []
            
                if since == -1 || since < changeNumber {
                    splitChange!.splits = splitCache.getAllSplits()
                }
            }
        }
        return splitChange
    }
}
