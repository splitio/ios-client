//
//  InMemorySplitCacheTests.swift
//  Split
//
//  Created by Brian Sztamfater on 5/10/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Split

class InMemorySplitCacheTests: QuickSpec {
    
    override func spec() {
        
        describe("InMemorySplitCacheTest") {
            
            let splitCache = InMemorySplitCache()

            context("Save Split Successfully") {
                
                it("should return a Split with the same values as it was saved") {
                    
                    let jsonSplit = "{\"name\":\"test\", \"status\":\"active\"}"
                    let split1 = try? JSON.encodeFrom(json: jsonSplit, to: Split.self)
                    _  = splitCache.addSplit(splitName: split1!.name!, split: split1!)

                    let jsonSplit2 = "{\"name\":\"test2\", \"status\":\"archived\"}"
                    let split2 = try? JSON.encodeFrom(json: jsonSplit2, to: Split.self)
                    _  = splitCache.addSplit(splitName: split2!.name!, split: split2!)

                    let cachedSplit = splitCache.getSplit(splitName: "test")
                    expect(cachedSplit).toNot(beNil())
                    expect(cachedSplit!.name!).to(equal("test"))
                    expect(cachedSplit!.status).to(equal(Status.Active))
                    expect(cachedSplit!.conditions).toNot(beNil())
                    expect(cachedSplit!.conditions?.count).to(equal(0))
                    expect(cachedSplit!.killed).to(beNil())
                }
            }
            
            context("Test getAllSplits") {

                it("should return 2 splits") {
                    let allCachedSplits = splitCache.getAllSplits()
                    expect(allCachedSplits).toNot(beNil())
                    expect(allCachedSplits.count).to(equal(2))
                    expect(allCachedSplits[0]).toNot(beNil())
                }
            }
            
            context("Test Remove One Split") {
                
                it("getSplit should return nil when getting a removed split") {
                    _ = splitCache.removeSplit(splitName: "test")
                    let removedSplit = splitCache.getSplit(splitName: "test")
                    expect(removedSplit).to(beNil())
                }
            }
            
            context("Test Clear Cache") {
                
                it("getAllSplits should return an empty array") {
                    splitCache.clear()
                    let allCachedSplitsShouldBeEmpty = splitCache.getAllSplits()
                    expect(allCachedSplitsShouldBeEmpty).toNot(beNil())
                    expect(allCachedSplitsShouldBeEmpty.count).to(equal(0))
                }
            }
            
        }
    }
}
