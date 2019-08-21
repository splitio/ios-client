//
//  LocalSplitFetcher.swift
//  Split
//
//  Created by Javier on 05/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

class LocalSplitFetcher: SplitFetcher {

    private let splitCache: SplitCacheProtocol
    init(splitCache: SplitCacheProtocol) {
        self.splitCache = splitCache
    }

    func fetch(splitName: String) -> Split? {
        return splitCache.getSplit(splitName: splitName)
    }

    func fetchAll() -> [Split]? {
        return splitCache.getAllSplits()
    }

    func forceRefresh() {
        // Nothing to refresh
    }
}
