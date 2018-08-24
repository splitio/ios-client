//
//  MySegmentsFetcherTests.swift
//  Split
//
//  Created by Brian Sztamfater on 4/10/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
import OHHTTPStubs

@testable import Split

class MySegmentsFetcherTests: QuickSpec {
    
    override func spec() {
        
        describe("SplitChangeFetcher") {
            
            var mySegmentsFetcher: MySegmentsChangeFetcher!
            let storage = FileAndMemoryStorage()
            
            beforeEach {
                mySegmentsFetcher = HttpMySegmentsFetcher(restClient: RestClient(), storage: storage)
            }
            
            context("Fetch MySegments Successfully") {
                
                it("should return an array of strings") {
                    
                    stub(condition: pathMatches("/api/mysegments/.*", options:[.caseInsensitive])) { _ in
                        let stubPath = OHPathForFile("mysegments_1.json", type(of: self))
                        return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                    }
                    
                    let response = try? mySegmentsFetcher.fetch(user: "test")
                    expect(response).toEventuallyNot(beNil())
                    if let response = response {
                        expect(response!.count).to(beGreaterThan(0))
                        expect(response![0]).to(equal("splitters"))
                    }
                }
            }
            
            context("Test MySegments With a Json with Renamed Parameters") {
                
                it("should return an array of two strings: 'test' and 'test1'") {
                    
                    stub(condition: pathMatches("/api/mysegments/.*", options:[.caseInsensitive])) { _ in
                        let stubPath = OHPathForFile("mysegments_2.json", type(of: self))
                        return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                    }
                    
                    let response = try? mySegmentsFetcher.fetch(user: "test")
                    
                    expect(response).toEventuallyNot(beNil())
                    if let response = response {
                        expect(response!.count).to(equal(2))
                        expect(response![0]).to(equal("test"))
                        expect(response![1]).to(equal("test1"))
                    }
                }
                
            }
            
            context("Test MySegments With a Json without mySegments parameter") {
                
                it("should return an empty array") {
                    
                    stub(condition: pathMatches("/api/mysegments/.*", options:[.caseInsensitive])) { _ in
                        let stubPath = OHPathForFile("mysegments_3.json", type(of: self))
                        return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                    }
                    
                    let response = try? mySegmentsFetcher.fetch(user: "test")
                    
                    expect(response).toEventuallyNot(beNil())
                    if let response = response {
                        expect(response!.count).to(equal(0))
                    }
                }
            }
            
            afterEach {
                OHHTTPStubs.removeAllStubs()
            }
        }
    }
}
