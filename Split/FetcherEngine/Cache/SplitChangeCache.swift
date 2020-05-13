//
//  SplitChangeCache.swift
//  Split
//
//  Created by Natalia  Stele on 06/12/2017.

import Foundation

class  SplitChangeCache: SplitChangeCacheProtocol {

    private let queue = DispatchQueue(label: "io.Split.FetcherEngine.Cache.SplitChangeCache.SyncQueue")
    var splitCache: SplitCacheProtocol?

    init(splitCache: SplitCacheProtocol) {
        self.splitCache = splitCache
    }

    func addChange(splitChange: SplitChange) -> Bool {

        if splitCache == nil {
            return false
        }

        queue.sync {
            _ = self.splitCache?.setChangeNumber(splitChange.till!)
            for split in splitChange.splits! {
                _ = self.splitCache?.addSplit(splitName: split.name!, split: split)
            }
            self.splitCache?.setTimestamp(timestamp: Int(Date().timeIntervalSince1970))
        }
        return true
    }

    func getChanges(since: Int64) -> SplitChange? {

        guard let splitCache = self.splitCache else {
            return nil
        }

        var splitChange: SplitChange?
        queue.sync {
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
