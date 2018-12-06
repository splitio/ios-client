//
//  InMemoryMySegmentsCacheTests.swift
//  Split
//
//  Created by Brian Sztamfater on 5/10/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Split

class InMemoryMySegmentsCacheTests: QuickSpec {
    
    override func spec() {
        
        describe("InMemoryMySegmentsCacheTest") {
            
            let mySegmentsCache = InMemoryMySegmentsCache(segments: [])

            context("Save MySegments Successfully") {
                
                it("should return an array of strings with the same values as it was saved") {
                    mySegmentsCache.addSegments(["segment1", "segment2", "segment3"])
                    
                    let segments = mySegmentsCache.getSegments()
                    expect(segments).toNot(beNil())
                    expect(segments.count).to(equal(3))
                }
                
            }
            
            context("Test IsInSegment") {
                
                it("should return true when passing segments1 and segment2, and false on segment4") {
                    expect(mySegmentsCache.isInSegments(name: "segment1")).to(beTrue())
                        
                    expect(mySegmentsCache.isInSegments(name: "segment4")).to(beFalse())
                        
                    expect(mySegmentsCache.isInSegments(name: "segment2")).to(beTrue())
                }
            }
            
            context("Test RemoveSegment") {

                it("isInSegment should return false when passing segments2") {
                    mySegmentsCache.removeSegments()
                    expect(mySegmentsCache.isInSegments(name: "segment2")).to(beFalse())
                }
            }
            
            context("Test Clear Cache") {
                
                it("getSegments should return an empty array") {
                    mySegmentsCache.clear()
                    expect(mySegmentsCache.getSegments()).to(beEmpty())
                }
            }
        }
    }
}
