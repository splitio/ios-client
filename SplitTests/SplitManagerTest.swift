//
//  SplitEventsManagerTest.swift
//  Split_Tests
//
//  Created by Sebastian Arrubia on 4/24/18.
//  Copyright © 2018 CocoaPods. All rights reserved.

import Foundation
import XCTest

@testable import Split

class SplitManagerTest: XCTestCase {
    
    var loadedSplits: [Split]!
    var manager: SplitManager!
    var splitsStorage: SplitsStorageStub!

    override func setUp() {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "splits", ofType: "json")!
        let json = try? Data(contentsOf: URL(fileURLWithPath: path)).stringRepresentation
        loadedSplits = try? JSON.decodeFrom(json: json!, to: [Split].self)
        splitsStorage = SplitsStorageStub()
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: loadedSplits, archivedSplits: [],
                                                               changeNumber: 1, updateTimestamp: 100))
        manager = DefaultSplitManager(splitsStorage: splitsStorage)
    }

    func testInitialSplitLoaded() {
        
        let splits = manager.splitNames
        let names = manager.splitNames
        
        var expectedSplitNames = [String]()
        for i in 0...5 {
            expectedSplitNames.append("sample_feature\(i)")
        }
        XCTAssertEqual(splits.count, 6, "Split count should be 6")
        XCTAssertEqual(names.sorted().joined(separator: ",").lowercased(), expectedSplitNames.joined(separator: ","), "Loaded splits names are not correct")
        
        let splitLowercase = manager.split(featureName: "sample_feature0")
        XCTAssertNotNil(splitLowercase, "Lowercase feature flag should be found")
        XCTAssertEqual(splitLowercase?.name?.lowercased(), "sample_feature0", "Lowercase feature flag name is not equal to expected")
        
        let splitUppercase = manager.split(featureName: "SAMPLE_FEATURE0")
        XCTAssertNotNil(splitUppercase, "Uppercase feature flag should be found")
        XCTAssertEqual(splitUppercase?.name?.lowercased(), "sample_feature0", "Uppercase feature flag name is not equal to expected")
        
        let splitNotExistent = manager.split(featureName: "SAMPLE_FEATURE99")
        XCTAssertNil(splitNotExistent, "Non existent feature flag should be nil")
    }
    
    func testSplitInfo() {
        
        let split0 = manager.split(featureName: "sample_feature0")
        let treatments0 = split0?.treatments

        let splitWithoutSets = manager.split(featureName: "sample_feature1")

        XCTAssertEqual(split0?.name?.lowercased(), "sample_feature0", "Split0 name")
        XCTAssertEqual(split0?.changeNumber, 1, "Split0 change number")
        XCTAssertFalse(split0?.killed ?? true, "Split0 killed")
        XCTAssertEqual(split0?.trafficType, "custom", "Split0 traffic type")
        XCTAssertEqual(split0?.sets?.sorted(), ["set1", "set2"])
        XCTAssertNotNil(split0?.configs)
        XCTAssertTrue(split0?.impressionsDisabled ?? false, "Split0 track impressions")
        XCTAssertEqual(split0?.prerequisites?.first?.n, "flag1")
        XCTAssertEqual(split0?.prerequisites?.first?.ts?.sorted(), ["on", "v1"])
        XCTAssertEqual(treatments0?.count, 6, "Split0 treatment count")
        XCTAssertEqual(treatments0?.sorted().joined(separator: ",").lowercased(), "t1_0,t2_0,t3_0,t4_0,t5_0,t6_0", "Split0 treatment names")
        
        let split1 = manager.split(featureName: "sample_feature1")
        let treatments1 = split1?.treatments
        
        XCTAssertEqual(split1?.name?.lowercased(), "sample_feature1", "Split1 name")
        XCTAssertEqual(split1?.changeNumber, 1, "Split1 change number")
        XCTAssertTrue(split1?.killed ?? false, "Split1 killed")
        XCTAssertEqual(split1?.trafficType, "custom1", "Split1 traffic type")
        XCTAssertEqual(split1?.defaultTreatment, "off", "Split1 traffic type")
        XCTAssertEqual(split1?.prerequisites, [])
        XCTAssertNotNil(split1?.configs)
        XCTAssertEqual(0, split1?.configs?.count)
        XCTAssertEqual(treatments1?.count, 6, "Split1 treatment count")
        XCTAssertEqual(treatments1?.sorted().joined(separator: ",").lowercased(), "t1_1,t2_1,t3_1,t4_1,t5_1,t6_1", "Split1 treatment names")

        XCTAssertEqual([], splitWithoutSets!.sets!)
        XCTAssertFalse(splitWithoutSets!.impressionsDisabled, "Split1 track impressions")
    }

    func testAddOneSplit() {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "split_sample_feature6", ofType: "json")!
        let newSplit = try! JSON(Data(contentsOf: URL(fileURLWithPath: path))).decode(Split.self)!
        splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [newSplit], archivedSplits: [],
                                                               changeNumber: 2, updateTimestamp: 200))
        let splits = manager.splits
        let names = manager.splitNames
        XCTAssertEqual(splits.count, 7, "Added one feature flag count")
        XCTAssertEqual(names.sorted().joined(separator: ",").lowercased(), "sample_feature0,sample_feature1,sample_feature2,sample_feature3,sample_feature4,sample_feature5,sample_feature6", "Added one feature flag name check")
    }

    func testEmptyName(){
        let split = manager.split(featureName: "  ")
        XCTAssertNil(split)
    }
}
