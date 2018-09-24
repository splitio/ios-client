//
//  SplitEventsManagerTest.swift
//  Split_Tests
//
//  Created by Sebastian Arrubia on 4/24/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Split

class SplitManagerTest: QuickSpec {
    
    override func spec() {
        
        describe("SplitManagerTest") {
            let bundle = Bundle(for: type(of: self))
            let path = bundle.path(forResource: "splits", ofType: "json")!
            let json = try? Data(contentsOf: URL(fileURLWithPath: path)).stringRepresentation
            let loadedSplits = try? JSON.encodeFrom(json: json!, to: [Split].self)
            context("Initial split loaded") {
                let cache: SplitCacheProtocol = SplitCacheStub(splits: loadedSplits!, changeNumber:1)
                let fetcher: SplitFetcher = LocalSplitFetcher(splitCache: cache)
                let manager: SplitManagerProtocol = SplitManager(splitFetcher: fetcher)
                let splits = manager.splitNames
                let names = manager.splitNames
                
                it("split count") {
                    expect(splits.count).to(equal(6))
                }
                
                it("Names are ok"){
                   expect(names.sorted().joined(separator: ",").lowercased()).to(equal("sample_feature0,sample_feature1,sample_feature2,sample_feature3,sample_feature4,sample_feature5"))
                }

                describe("Search By Name"){
                    context("Name Lowercase"){
                        let split = manager.split(featureName: "sample_feature0")
                        it("Found"){
                            expect(split).toNot(beNil())
                            expect(split?.name?.lowercased()).to(equal("sample_feature0"))
                        }
                    }
                    
                    context("Name Uppercase"){
                        let split = manager.split(featureName: "SAMPLE_FEATURE0")
                        it("Found"){
                            expect(split).toNot(beNil())
                            expect(split?.name?.lowercased()).to(equal("sample_feature0"))
                        }
                    }
                    
                    context("Non Existing"){
                        let split = manager.split(featureName: "SAMPLE_FEATURE99")
                        it("Not Found"){
                            expect(split).to(beNil())
                        }
                    }
                }
                
                describe("Check Split"){
                    context("Feature 0"){
                        let split = manager.split(featureName: "sample_feature0")!
                        let treatments = split.treatments!
                        
                        it("Basic Info"){
                            expect(split.name!.lowercased()).to(equal("sample_feature0"))
                            expect(split.changeNumber).to(equal(1))
                            expect(split.killed).to(beFalse())
                            expect(split.trafficType).to(equal("custom"))
                        }
                        
                        it("Treatments"){
                            expect(treatments.count).to(equal(6))
                             expect(treatments.sorted().joined(separator: ",").lowercased()).to(equal("t1_0,t2_0,t3_0,t4_0,t5_0,t6_0"))
                        }
                    }
                    context("Feature 1"){
                        let split = manager.split(featureName: "sample_feature1")!
                        let treatments = split.treatments!
                        
                        it("Basic Info"){
                            expect(split.name!.lowercased()).to(equal("sample_feature1"))
                            expect(split.changeNumber).to(equal(1))
                            expect(split.killed).toNot(beFalse())
                            expect(split.trafficType).to(equal("custom1"))
                        }
                        
                        it("Treatments"){
                            expect(treatments.count).to(equal(6))
                            expect(treatments.sorted().joined(separator: ",").lowercased()).to(equal("t1_1,t2_1,t3_1,t4_1,t5_1,t6_1"))
                        }
                    }
                }
            }
            
            context("Added One Split") {
                let cache: SplitCacheProtocol = SplitCacheStub(splits: loadedSplits!, changeNumber: 1)
                let fetcher: SplitFetcher = LocalSplitFetcher(splitCache: cache)
                let manager: SplitManagerProtocol = SplitManager(splitFetcher: fetcher)
                let path = bundle.path(forResource: "split_sample_feature6", ofType: "json")!
                let newSplit = try! JSON(Data(contentsOf: URL(fileURLWithPath: path))).decode(Split.self)!
                cache.addSplit(splitName: newSplit.name!, split: newSplit)
                cache.setChangeNumber(2)
                let splits = manager.splits
                let names = manager.splitNames
                it("split count") {
                    expect(splits.count).to(equal(7))
                }
                
                it("Names are ok"){
                    expect(names.sorted().joined(separator: ",").lowercased()).to(equal("sample_feature0,sample_feature1,sample_feature2,sample_feature3,sample_feature4,sample_feature5,sample_feature6"))
                }
            }
            
            context("Removed One Split") {
                let cache: SplitCacheProtocol = SplitCacheStub(splits: loadedSplits!, changeNumber: 1)
                let fetcher: SplitFetcher = LocalSplitFetcher(splitCache: cache)
                let manager: SplitManagerProtocol = SplitManager(splitFetcher: fetcher)
                cache.removeSplit(splitName: "sample_feature4")
                cache.setChangeNumber(2)
                let splits = manager.splits
                let names = manager.splitNames
                it("split count") {
                    expect(splits.count).to(equal(5))
                }
                
                it("Names are ok"){
                    expect(names.sorted().joined(separator: ",").lowercased()).to(equal("sample_feature0,sample_feature1,sample_feature2,sample_feature3,sample_feature5"))
                }
            }
            
        }
        
    }
    
    
    
}
