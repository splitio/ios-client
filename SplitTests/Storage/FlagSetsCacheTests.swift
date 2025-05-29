//
//  FlagSetsCacheTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 29/09/2023.
//  Copyright © 2023 Split. All rights reserved.
//

@testable import Split
import XCTest

class FlagSetsCacheTests: XCTestCase {
    var cache: FlagSetsCache!

    override func setUp() {}

    func testAddToFlagSetsNoFilter() {
        cache = DefaultFlagSetsCache(setsInFilter: nil)

        for i in 1 ..< 3 {
            cache.addToFlagSets(TestingHelper.createSplit(name: "name_\(i)", sets: ["s1", "s2"]))
        }

        for i in 1 ..< 3 {
            cache.addToFlagSets(TestingHelper.createSplit(name: "name_1\(i)", sets: ["s2"]))
        }

        for i in 1 ..< 3 {
            cache.addToFlagSets(TestingHelper.createSplit(name: "name_2\(i)", sets: ["s3"]))
        }

        let featureFlags = cache.getFeatureFlagNames(forFlagSets: ["s1", "s2"])

        XCTAssertEqual(["name_1", "name_11", "name_12", "name_2"], featureFlags.sorted())
    }

    func testRemoveFromFlagSetsNoFilter() {
        cache = DefaultFlagSetsCache(setsInFilter: nil)
        for i in 1 ..< 4 {
            cache.addToFlagSets(TestingHelper.createSplit(name: "name_\(i)", sets: ["s1", "s2", "s3"]))
        }

        cache.removeFromFlagSets(featureFlagName: "name_1", sets: Set(["s2"]))
        cache.removeFromFlagSets(featureFlagName: "name_3", sets: Set(["s3"]))

        let featureFlagsS1 = cache.getFeatureFlagNames(forFlagSets: ["s1"])
        let featureFlagsS2 = cache.getFeatureFlagNames(forFlagSets: ["s2"])
        let featureFlagsS3 = cache.getFeatureFlagNames(forFlagSets: ["s3"])

        XCTAssertEqual(["name_1", "name_2", "name_3"], featureFlagsS1.sorted())
        XCTAssertEqual(["name_2", "name_3"], featureFlagsS2.sorted())
        XCTAssertEqual(["name_1", "name_2"], featureFlagsS3.sorted())
    }

    func testAddToFlagSetsWithFilter() {
        cache = DefaultFlagSetsCache(setsInFilter: ["s1", "s2", "s5"])

        for i in 1 ..< 3 {
            cache.addToFlagSets(TestingHelper.createSplit(name: "name_\(i)", sets: ["s1", "s2"]))
        }

        for i in 1 ..< 3 {
            cache.addToFlagSets(TestingHelper.createSplit(name: "name_1\(i)", sets: ["s2", "s5"]))
        }

        for i in 1 ..< 3 {
            cache.addToFlagSets(TestingHelper.createSplit(name: "name_2\(i)", sets: ["s3"]))
        }

        let featureFlagsS1 = cache.getFeatureFlagNames(forFlagSets: ["s1", "s2"])
        let featureFlagsS3 = cache.getFeatureFlagNames(forFlagSets: ["s3"])
        let featureFlagsS5 = cache.getFeatureFlagNames(forFlagSets: ["s5"])

        XCTAssertEqual(["name_1", "name_11", "name_12", "name_2"], featureFlagsS1.sorted())
        XCTAssertEqual([], featureFlagsS3.sorted())
        XCTAssertEqual(["name_11", "name_12"], featureFlagsS5.sorted())
    }

    private func getFilter(sets: [String]) -> SplitFilter {
        return SplitFilter(type: .bySet, values: sets)
    }
}
