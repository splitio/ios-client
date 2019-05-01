//
//  SplitFetcherStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 27/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitFetcherStub: SplitFetcher {

    var splits: [String: Split]
    
    init(splits: [Split]) {
        var splitsMap = [String: Split]()
        for split in splits {
            if let name = split.name {
                splitsMap[name] = split
            }
        }
        self.splits = splitsMap
    }
    
    func fetch(splitName: String) -> Split? {
        return splits[splitName]
    }
    
    func fetchAll() -> [Split]? {
        return Array(splits.values)
    }
    
    func forceRefresh() {
    }
    
    
}
