//
//  MySegmentsFetcherStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 27/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

class MySegmentsFetcherStub: MySegmentsFetcher, QueryableMySegmentsFetcher {
    var mySegments: Set<String>
    
    init(mySegments: [String]) {
        self.mySegments = Set(mySegments)
    }
    
    // MARK: MySegmentsFetcher
    func fetchAll() -> [String] {
        return Array(mySegments)
    }
    
    func forceRefresh() {
    }
    
    // MARK: QueryableMySegmentsFetcher
    func isInSegments(name: String) -> Bool {
        return mySegments.contains(name)
    }
}
