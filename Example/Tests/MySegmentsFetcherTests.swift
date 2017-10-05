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
import Mockingjay
import SwiftyJSON

@testable import Split

class MySegmentsFetcherTests: QuickSpec {
    
    override func spec() {
        
        describe("SplitChangeFetcher") {
            
            var mySegmentsFetcher: MySegmentsFetcher!
            
            beforeEach {
                mySegmentsFetcher = HttpMySegmentsFetcher(restClient: RestClient())
            }
            
            context("Fetch MySegments Successfully") {
                
                it("should return an array of strings") {
                    
                    let path = Bundle(for: type(of: self)).path(forResource: "mysegments_1", ofType: "json")!
                    let data = Data(referencing: NSData(contentsOfFile: path)!)
                    self.stub(uri("/api/mySegments/{user}"), jsonData(data))
                    
                    let response = try? mySegmentsFetcher.fetch(user: "test")
                    
                    expect(response).toEventuallyNot(beNil())
                    expect(response!.count).to(beGreaterThan(0))
                    expect(response![0]).to(equal("splitters"))
                }
                
            }
            
            context("Test MySegments With a Json with Renamed Parameters") {
                
                it("should return an array of two strings: 'test' and 'test1'") {
                    
                    let path = Bundle(for: type(of: self)).path(forResource: "mysegments_2", ofType: "json")!
                    let data = Data(referencing: NSData(contentsOfFile: path)!)
                    self.stub(uri("/api/mySegments/{user}"), jsonData(data))
                    
                    let response = try? mySegmentsFetcher.fetch(user: "test")
                    
                    expect(response).toEventuallyNot(beNil())
                    expect(response!.count).to(equal(2))
                    expect(response![0]).to(equal("test"))
                    expect(response![1]).to(equal("test1"))
                }
                
            }
            
            context("Test MySegments With a Json without mySegments parameter") {
                
                it("should return an empty array") {
                    
                    let path = Bundle(for: type(of: self)).path(forResource: "mysegments_3", ofType: "json")!
                    let data = Data(referencing: NSData(contentsOfFile: path)!)
                    self.stub(uri("/api/mySegments/{user}"), jsonData(data))
                    
                    let response = try? mySegmentsFetcher.fetch(user: "test")
                    
                    expect(response).toEventuallyNot(beNil())
                    expect(response!.count).to(equal(0))
                }
                
            }
            
        }
    }
}
