//
//  InRuleBasedSegmentMatcherTest.swift
//  SplitTests
//
//  Copyright 2025 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class InRuleBasedSegmentMatcherTest: XCTestCase {
    private var ruleBasedSegmentsStorage: RuleBasedSegmentsStorageStub!
    private var mySegmentsStorage: MySegmentsStorageStub!
    private var evalContext: EvalContext!

    override func setUp() {
        super.setUp()

        ruleBasedSegmentsStorage = RuleBasedSegmentsStorageStub()
        mySegmentsStorage = MySegmentsStorageStub()
        evalContext = EvalContext(
            evaluator: nil,
            mySegmentsStorage: mySegmentsStorage,
            myLargeSegmentsStorage: nil,
            ruleBasedSegmentsStorage: ruleBasedSegmentsStorage)
    }

    override func tearDown() {
        ruleBasedSegmentsStorage = nil
        mySegmentsStorage = nil
        evalContext = nil

        super.tearDown()
    }

    func testEvaluateWithNilSegmentName() {
        let matcher = createMatcher(data: nil)
        XCTAssertFalse(matcher.evaluate(
            values: EvalValues(matchValue: "key1", matchingKey: "key1"),
            context: evalContext))
    }

    func testEvaluateWithNilRuleBasedSegmentsStorage() {
        let data = UserDefinedBaseSegmentMatcherData()
        data.segmentName = "segment1"
        let matcher = createMatcher(data: data)

        XCTAssertFalse(matcher.evaluate(values: EvalValues(matchValue: "key1", matchingKey: "key1"), context: nil))
    }

    func testEvaluateWithNonExistingSegment() {
        let data = UserDefinedBaseSegmentMatcherData()
        data.segmentName = "non_existing_segment"
        let matcher = createMatcher(data: data)

        XCTAssertFalse(matcher.evaluate(
            values: EvalValues(matchValue: "key1", matchingKey: "key1"),
            context: evalContext))
    }

    // MARK: - Exclusion Tests

    func testEvaluateWithKeyInExcludedKeys() {
        // Setup a segment with excluded keys
        let segment = createSegment(name: "segment1")
        segment.excluded = Excluded()
        segment.excluded?.keys = ["key1", "key2"]
        ruleBasedSegmentsStorage.segments["segment1"] = segment

        let data = UserDefinedBaseSegmentMatcherData()
        data.segmentName = "segment1"
        let matcher = createMatcher(data: data)

        XCTAssertFalse(matcher.evaluate(
            values: EvalValues(matchValue: "key1", matchingKey: "key1"),
            context: evalContext))
    }

    func testEvaluateWithKeyInExcludedSegments() {
        let segment = createSegment(name: "segment1")
        segment.excluded = Excluded()
        segment.excluded?.segments = [ExcludedSegment(name: "excluded_segment", type: .standard)]
        ruleBasedSegmentsStorage.segments["segment1"] = segment

        mySegmentsStorage.segments["key1"] = Set(["excluded_segment"])

        let data = UserDefinedBaseSegmentMatcherData()
        data.segmentName = "segment1"
        let matcher = createMatcher(data: data)

        XCTAssertFalse(matcher.evaluate(
            values: EvalValues(matchValue: "key1", matchingKey: "key1"),
            context: evalContext))
    }

    func testEvaluateWithNoConditions() {
        let segment = createSegment(name: "segment1")
        segment.conditions = nil
        ruleBasedSegmentsStorage.segments["segment1"] = segment

        let data = UserDefinedBaseSegmentMatcherData()
        data.segmentName = "segment1"
        let matcher = createMatcher(data: data)

        XCTAssertFalse(matcher.evaluate(
            values: EvalValues(matchValue: "key1", matchingKey: "key1"),
            context: evalContext))
    }

    func testEvaluateWithEmptyConditions() {
        let segment = createSegment(name: "segment1")
        segment.conditions = []
        ruleBasedSegmentsStorage.segments["segment1"] = segment

        let data = UserDefinedBaseSegmentMatcherData()
        data.segmentName = "segment1"
        let matcher = createMatcher(data: data)

        XCTAssertFalse(matcher.evaluate(
            values: EvalValues(matchValue: "key1", matchingKey: "key1"),
            context: evalContext))
    }

    func testEvaluateWithMatchingCondition() {
        let segment = createSegment(name: "segment1")
        let allKeysMatcher = createAllKeysMatcher()
        let matcherGroup = createMatcherGroup(matchers: [allKeysMatcher])
        let condition = createCondition(matcherGroup: matcherGroup)

        segment.conditions = [condition]
        ruleBasedSegmentsStorage.segments["segment1"] = segment

        let data = UserDefinedBaseSegmentMatcherData()
        data.segmentName = "segment1"
        let matcher = createMatcher(data: data)

        XCTAssertTrue(matcher.evaluate(
            values: EvalValues(matchValue: "key1", matchingKey: "key1"),
            context: evalContext))
    }

    func testEvaluateWithNonMatchingCondition() {
        let segment = createSegment(name: "segment1")

        let whitelistMatcher = createWhitelistMatcher(whitelist: ["other_key1", "other_key2"])
        let matcherGroup = createMatcherGroup(matchers: [whitelistMatcher])
        let condition = createCondition(matcherGroup: matcherGroup)

        segment.conditions = [condition]
        ruleBasedSegmentsStorage.segments["segment1"] = segment

        let data = UserDefinedBaseSegmentMatcherData()
        data.segmentName = "segment1"
        let matcher = createMatcher(data: data)

        XCTAssertFalse(matcher.evaluate(
            values: EvalValues(matchValue: "key1", matchingKey: "key1"),
            context: evalContext))
    }

    func testEvaluateWithMultipleConditions() {
        let segment = createSegment(name: "segment1")

        // Non-matching condition
        let whitelistMatcher = createWhitelistMatcher(whitelist: ["other_key1", "other_key2"])
        let nonMatchingMatcherGroup = createMatcherGroup(matchers: [whitelistMatcher])
        let nonMatchingCondition = createCondition(matcherGroup: nonMatchingMatcherGroup)

        // Matching condition
        let allKeysMatcher = createAllKeysMatcher()
        let matchingMatcherGroup = createMatcherGroup(matchers: [allKeysMatcher])
        let matchingCondition = createCondition(matcherGroup: matchingMatcherGroup)

        segment.conditions = [nonMatchingCondition, matchingCondition]
        ruleBasedSegmentsStorage.segments["segment1"] = segment

        let data = UserDefinedBaseSegmentMatcherData()
        data.segmentName = "segment1"
        let matcher = createMatcher(data: data)

        XCTAssertTrue(matcher.evaluate(
            values: EvalValues(matchValue: "key1", matchingKey: "key1"),
            context: evalContext))
    }

    private func createSegment(name: String, status: Status = .active) -> RuleBasedSegment {
        return RuleBasedSegment(name: name, status: status)
    }

    private func createAllKeysMatcher(negate: Bool = false) -> Matcher {
        let matcher = Matcher()
        matcher.matcherType = .allKeys
        matcher.negate = negate
        return matcher
    }

    private func createWhitelistMatcher(whitelist: [String], negate: Bool = false) -> Matcher {
        let matcher = Matcher()
        matcher.matcherType = .whitelist
        matcher.negate = negate
        matcher.whitelistMatcherData = WhitelistMatcherData()
        matcher.whitelistMatcherData?.whitelist = whitelist
        return matcher
    }

    private func createMatcherGroup(matchers: [Matcher], combiner: MatcherCombiner = .and) -> MatcherGroup {
        let matcherGroup = MatcherGroup()
        matcherGroup.matcherCombiner = combiner
        matcherGroup.matchers = matchers
        return matcherGroup
    }

    private func createCondition(matcherGroup: MatcherGroup, conditionType: ConditionType = .rollout) -> Condition {
        let condition = Condition()
        condition.conditionType = conditionType
        condition.matcherGroup = matcherGroup
        return condition
    }

    private func createMatcher(data: UserDefinedBaseSegmentMatcherData?) -> InRuleBasedSegmentMatcher {
        return InRuleBasedSegmentMatcher(data: data)
    }
}
