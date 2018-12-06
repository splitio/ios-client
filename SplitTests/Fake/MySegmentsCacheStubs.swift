//
//  MySegmentsCacheStubs.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 09/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

@testable import Split

class MySegmentCacheStub: MySegmentsCacheProtocol {
    
    let segments: Set = ["s1", "s2", "s3"]
    
    func addSegments(_ segments: [String]) {
    }
    
    func removeSegments() {
    }
    
    func getSegments() -> [String] {
        return Array(segments)
    }
    
    func isInSegments(name: String) -> Bool {
        return true
    }
    
    func clear() {
    }
    
    
}
