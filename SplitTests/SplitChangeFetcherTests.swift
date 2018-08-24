//
//  SplitChangeFetcherTests.swift
//  Split
//
//  Created by Brian Sztamfater on 3/10/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

import Quick
import Nimble
import OHHTTPStubs

@testable import Split

class SplitChangeFetcherTests: QuickSpec {
    
    override func spec() {
        
        describe("SplitChangeFetcher") {
            
            var splitChangeFetcher: SplitChangeFetcher!
            let cache = SplitCache(storage: MemoryStorage())

            beforeEach {
                splitChangeFetcher = HttpSplitChangeFetcher(restClient: RestClient(), splitCache: cache)
            }
            
            context("Test a Json that changes its structure and is deserialized without exception. Contains: a field renamed, a field removed and a field added.") {
                
                it("should return a json of type object when server response is a json object") {
                    
                    stub(condition: isPath("/api/splitChanges")) { _ in
                        let stubPath = OHPathForFile("splitchanges_1.json", type(of: self))
                        return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                    }
                    
                    let response = try? splitChangeFetcher.fetch(since: -1)
                    expect(response).toEventuallyNot(beNil())
                    if let response = response {
                        expect(response!.splits!.count).toEventually(beGreaterThan(0))
                    }
                }
                
            }
            
            context("Fetch SplitChanges Successfully") {
                
                it("should return a json of type object when server response is a json object with some extra parameters") {
                    
                    stub(condition: pathMatches("/api/splitChanges")) { _ in
                        let stubPath = OHPathForFile("splitchanges_2.json", type(of: self))
                        return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                    }
                    
                    let response = try? splitChangeFetcher.fetch(since: -1)
                    
                    expect(response).toEventuallyNot(beNil())
                    if let response = response {
                        expect(response!.splits!.count).to(equal(1))
                        
                        let split = response!.splits![0];
                        expect(split.name).to(equal("FACUNDO_TEST"))
                        expect(split.killed).to(equal(false))
                        expect(split.status).to(equal(Status.Active))
                        expect(split.trafficTypeName).to(equal("account"))
                        expect(split.defaultTreatment).to(equal("off"))
                        expect(split.conditions).toNot(beNil())
                        expect(response!.since).to(equal(-1))
                        expect(response!.till).to(equal(1506703262916))
                        expect(split.algo).to(beNil())
                    }
                }
                
            }
            
            context("Fetch SplitChanges With Empty Response") {
                
                it("splits, till and since should be nil") {
                    stub(condition: isPath("/api/splitChanges")) { _ in
                        let stubPath = OHPathForFile("splitchanges_3.json", type(of: self))
                        return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
                    }
                    
                    let response = try? splitChangeFetcher.fetch(since: -1)
                    
                    expect(response).toEventuallyNot(beNil())
                    if let response = response {
                        expect(response!.splits).to(beNil())
                        expect(response!.since).to(beNil())
                        expect(response!.till).to(beNil())
                    }
                }
                
            }
            
            afterEach {
                OHHTTPStubs.removeAllStubs()
            }
        }
    }
}
