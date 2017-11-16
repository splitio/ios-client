//
//  HashingTest.swift
//  Split
//
//  Created by Natalia  Stele on 11/9/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
import SwiftyJSON

@testable import Split

class HashingTest: QuickSpec {
    
    override func spec() {
        
        describe("HashingTest") {
            
            context("Murmur3 returns the bucket expected") {
                
                let seed: Int = 467569525
                let key: String = "EPxM1cYQnL4AuqD"
                
                let bucket = Splitter.shared.getBucket(seed: seed, key: key, algo: 0)
                
                expect(bucket).toNot(beNil())
                expect(segments.count).to(equal(79))
                
            }
            
        }
        
    }

}
