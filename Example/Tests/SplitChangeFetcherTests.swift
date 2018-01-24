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
import Mockingjay
import SwiftyJSON

@testable import Split

class SplitChangeFetcherTests: QuickSpec {
    
    override func spec() {
        
        describe("SplitChangeFetcher") {
            
            var splitChangeFetcher: SplitChangeFetcher!
            let storage = FileAndMemoryStorage()

            beforeEach {
                splitChangeFetcher = HttpSplitChangeFetcher(restClient: RestClient(), storage: storage)
            }
            
            context("Test a Json that changes its structure and is deserialized without exception. Contains: a field renamed, a field removed and a field added.") {
                
                it("should return a json of type object when server response is a json object") {
                    
                    let path = Bundle(for: type(of: self)).path(forResource: "splitchanges_1", ofType: "json")!
                    let data = Data(referencing: NSData(contentsOfFile: path)!)
                    self.stub(uri("/api/splitChanges"), jsonData(data))
                    
                    let response = try? splitChangeFetcher.fetch(since: -1)
                    
                    expect(response).toEventuallyNot(beNil())
                    expect(response!.splits).toEventuallyNot(beNil())
                    expect(response!.splits!.count).toEventually(beGreaterThan(0))
                }
                
            }
            
            context("Fetch SplitChanges Successfully") {
                
                it("should return a json of type object when server response is a json object with some extra parameters") {
                    
                    let path = Bundle(for: type(of: self)).path(forResource: "splitchanges_2", ofType: "json")!
                    let data = Data(referencing: NSData(contentsOfFile: path)!)
                    self.stub(uri("/api/splitChanges"), jsonData(data))
                    
                    let response = try? splitChangeFetcher.fetch(since: -1)
                    
                    expect(response).toEventuallyNot(beNil())
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
            
            context("Fetch SplitChanges With Empty Response") {
                
                it("splits, till and since should be nil") {
                    
                    let path = Bundle(for: type(of: self)).path(forResource: "splitchanges_3", ofType: "json")!
                    let data = Data(referencing: NSData(contentsOfFile: path)!)
                    self.stub(uri("/api/splitChanges"), jsonData(data))
                    
                    let response = try? splitChangeFetcher.fetch(since: -1)
                    
                    expect(response).toEventuallyNot(beNil())
                    expect(response!.splits).to(beNil())
                    expect(response!.since).to(beNil())
                    expect(response!.till).to(beNil())
                }
                
            }
        }
    }
}
