//
//  YamlParserTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/04/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class LocalhostYamlParserTest: XCTestCase {
    var client: SplitClient!

    func testCorrectFile() {
        guard let content = FileHelper.readDataFromFile(sourceClass: self, name: "localhost", type: "yaml") else {
            XCTAssertTrue(false)
            return
        }

        let parser = YamlLocalhostSplitsParser()
        let splits = parser.parseContent(content)!

        XCTAssertEqual(9, splits.count)
        XCTAssertNotNil(splits["my_feature"])
        XCTAssertNotNil(splits["split_0"])
        XCTAssertNotNil(splits["split_1"])
        XCTAssertNotNil(splits["split_2"])
        XCTAssertNotNil(splits["other_feature_3"])
        XCTAssertNotNil(splits["x_feature"])
        XCTAssertNotNil(splits["other_feature"])
        XCTAssertNotNil(splits["other_feature_2"])

        XCTAssertEqual("my_feature", splits["my_feature"]?.name)
        XCTAssertEqual("other_feature_2", splits["other_feature_2"]?.name)

        XCTAssertEqual(3, splits["my_feature"]?.conditions?.count)

        XCTAssertEqual(SplitConstants.control, splits["my_feature"]?.defaultTreatment)
        XCTAssertEqual(ConditionType.whitelist, splits["my_feature"]?.conditions?[0].conditionType)
        XCTAssertEqual(ConditionType.whitelist, splits["my_feature"]?.conditions?[1].conditionType)
        XCTAssertEqual(ConditionType.rollout, splits["my_feature"]?.conditions?[2].conditionType)
        XCTAssertNil(splits["my_feature"]?.configurations?["white"])
        XCTAssertEqual(
            "{\"desc\" : \"this applies only to ON treatment\"}",
            splits["my_feature"]?.configurations?["on"])

        XCTAssertEqual(1, splits["split_0"]?.conditions?.count)
        XCTAssertEqual(SplitConstants.control, splits["split_0"]?.defaultTreatment)
        XCTAssertEqual("{ \"size\" : 20 }", splits["split_0"]?.configurations?["off"])

        XCTAssertEqual(SplitConstants.control, splits["x_feature"]?.defaultTreatment)
        XCTAssertEqual(ConditionType.whitelist, splits["x_feature"]?.conditions?[0].conditionType)
        XCTAssertEqual(ConditionType.whitelist, splits["x_feature"]?.conditions?[1].conditionType)
        XCTAssertNil(splits["x_feature"]?.configurations?["on"])
        XCTAssertEqual(
            "{\"desc\" : \"this applies only to OFF and only for only_key. The rest will receive ON\"}",
            splits["x_feature"]?.configurations?["off"])

        XCTAssertEqual(1, splits["other_feature_2"]?.conditions?.count)
        XCTAssertEqual(SplitConstants.control, splits["other_feature_2"]?.defaultTreatment)
        XCTAssertNil(splits["other_feature_2"]?.configurations)
    }

    func testMissingSplitData() {
        let content = "- s1:\n    treatment: \"t1\"\n- s2:\n"
        let parser = YamlLocalhostSplitsParser()
        let splits = parser.parseContent(content)!

        XCTAssertEqual(1, splits.count)

        XCTAssertEqual(1, splits["s1"]?.conditions?.count)
        XCTAssertEqual(SplitConstants.control, splits["s1"]?.defaultTreatment)
        XCTAssertNil(splits["s1"]?.configurations)

        XCTAssertNil(splits["s2"])
    }

    func testMissingSplitTreatment() {
        let content = "- s1:\n    treatment: \"t1\"\n- s2:\n    keys: \"thekey\""
        let parser = YamlLocalhostSplitsParser()
        let splits = parser.parseContent(content)!

        XCTAssertEqual(2, splits.count)

        XCTAssertEqual(1, splits["s1"]?.conditions?.count)
        XCTAssertEqual(SplitConstants.control, splits["s1"]?.defaultTreatment)
        XCTAssertNil(splits["s1"]?.configurations)

        XCTAssertEqual(1, splits["s2"]?.conditions?.count)
        XCTAssertEqual(SplitConstants.control, splits["s2"]?.defaultTreatment)
        XCTAssertEqual(ConditionType.whitelist, splits["s2"]?.conditions?[0].conditionType)
        XCTAssertNil(splits["s2"]?.configurations)
    }

    func testWrongFormat() {
        let content = "this is not yaml content"
        let parser = YamlLocalhostSplitsParser()
        let splits = parser.parseContent(content)
        XCTAssertEqual([:], splits)
    }

    func testMissingFirstSplit() {
        let content = "treatment: \"t1\"\n- s2:\n    keys: \"thekey\""
        let parser = YamlLocalhostSplitsParser()
        let splits = parser.parseContent(content)!
        XCTAssertEqual(1, splits.count)
    }
}
