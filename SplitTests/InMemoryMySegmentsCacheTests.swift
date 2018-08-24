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
            
            let mySegmentsCache = InMemoryMySegmentsCache()

            context("Save MySegments Successfully") {
                
                it("should return an array of strings with the same values as it was saved") {
                    mySegmentsCache.addSegments(segmentNames: ["segment1", "segment2", "segment3"], key: "some_user_key")
                    
                    let segments = mySegmentsCache.getSegments(key: "some_user_key")
                    expect(segments).toNot(beNil())
                    expect(segments?.count).to(equal(3))
                }
                
            }
            
            context("Test IsInSegment") {
                
                it("should return true when passing segments1 and segment2, and false on segment4") {
                    expect(mySegmentsCache.isInSegment(segmentName: "segment1", key: "some_user_key")).to(beTrue())
                        
                    expect(mySegmentsCache.isInSegment(segmentName: "segment4",key: "some_user_key")).to(beFalse())
                        
                    expect(mySegmentsCache.isInSegment(segmentName: "segment2",key: "some_user_key")).to(beTrue())
                }
            }
            
            context("Test RemoveSegment") {

                it("isInSegment should return false when passing segments2") {
                    mySegmentsCache.removeSegments()
                    expect(mySegmentsCache.isInSegment(segmentName: "segment2",key: "some_user_key")).to(beFalse())
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
