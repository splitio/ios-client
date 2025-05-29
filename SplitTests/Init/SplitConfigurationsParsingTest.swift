//
//  SplitConfigurationsParsingTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 25/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

@testable import Split
import XCTest

class SplitConfigurationsParsingTest: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEncodingOneBasicConfig() {
        let config = "{ \"treatment1\": \"{\\\"c1\\\": \\\"v1\\\"}\"}"
        let split = createAndParseSplit(config: config)
        let configData = jsonObj(config: split?.configurations?["treatment1"])

        XCTAssertNotNil(split)
        XCTAssertEqual("v1", configData?["c1"] as? String)
    }

    func testEncodingBasicArrayConfig() {
        let config = "{ \"treatment1\": \"{\\\"c1\\\": [1, 2.0, 3, 4.0]}\"}"
        let split = createAndParseSplit(config: config)
        let configData = jsonObj(config: split?.configurations?["treatment1"])
        let array = configData?["c1"] as? [Double]
        XCTAssertNotNil(split)
        XCTAssertEqual(4, array?.count)
        XCTAssertEqual(1, array?[0])
        XCTAssertEqual(2.0, array?[1])
        XCTAssertEqual(3, array?[2])
        XCTAssertEqual(4.0, array?[3])
    }

    func testEncodingMapArrayConfig() {
        let config =
            "{\"treatment1\": \"{\\\"a1\\\":[{\\\"f\\\":\\\"v1\\\"}, {\\\"f\\\":\\\"v2\\\"}, {\\\"f\\\":\\\"v3\\\"}], \\\"a2\\\":[{\\\"f1\\\":1, \\\"f2\\\":2, \\\"f3\\\":3}, {\\\"f1\\\":11, \\\"f2\\\": 12, \\\"f3\\\":13}]}\", \"treatment2\": \"{\\\"f1\\\":\\\"v1\\\"}\"}"
        let split = createAndParseSplit(config: config)
        let config1Data = jsonObj(config: split?.configurations?["treatment1"])
        let config2Data = jsonObj(config: split?.configurations?["treatment2"])
        let array1 = config1Data?["a1"] as? [[String: Any]]
        let array2 = config1Data?["a2"] as? [[String: Any]]
        let obj11 = array1?[0] as? [String: String]
        let obj12 = array1?[1] as? [String: String]
        let obj13 = array1?[2] as? [String: String]
        let obj21 = array2?[0] as? [String: Int]
        let obj22 = array2?[1] as? [String: Int]

        XCTAssertNotNil(split)
        XCTAssertNotNil(config1Data)
        XCTAssertNotNil(config2Data)
        XCTAssertNotNil(array1)
        XCTAssertNotNil(array2)
        XCTAssertEqual(3, array1?.count)
        XCTAssertEqual(2, array2?.count)

        XCTAssertEqual("v1", obj11?["f"])
        XCTAssertEqual("v2", obj12?["f"])
        XCTAssertEqual("v3", obj13?["f"])

        XCTAssertEqual(1, obj21?["f1"])
        XCTAssertEqual(2, obj21?["f2"])
        XCTAssertEqual(3, obj21?["f3"])
        XCTAssertEqual(11, obj22?["f1"])
        XCTAssertEqual(12, obj22?["f2"])
        XCTAssertEqual(13, obj22?["f3"])

        XCTAssertEqual("v1", config2Data?["f1"] as? String)
    }

    func testEncodingMultiTreatmentConfig() {
        let config =
            "{ \"treatment1\": \"{\\\"c1\\\": \\\"v1\\\"}\", \"treatment2\": \"{\\\"c1\\\": \\\"v1\\\"}\", \"treatment3\": \"{\\\"c1\\\": \\\"v1\\\"}\"}"
        let split = createAndParseSplit(config: config)
        let config1 = jsonObj(config: split?.configurations?["treatment1"])
        let config2 = jsonObj(config: split?.configurations?["treatment2"])
        let config3 = jsonObj(config: split?.configurations?["treatment3"])

        XCTAssertNotNil(split)
        XCTAssertEqual("v1", config1?["c1"] as? String)
        XCTAssertEqual("v1", config2?["c1"] as? String)
        XCTAssertEqual("v1", config3?["c1"] as? String)
    }

    func testEncodingAllValueTypesConfig() {
        let config =
            "{ \"double\": \"{\\\"c1\\\": 20576.85}\", \"string\": \"{\\\"c1\\\": \\\"v1\\\"}\", \"int\": \"{\\\"c1\\\": 123456}\", \"boolean\": \"{\\\"c1\\\": false}\"}"
        let split = createAndParseSplit(config: config)
        let double = jsonObj(config: split?.configurations?["double"])
        let string = jsonObj(config: split?.configurations?["string"])
        let int = jsonObj(config: split?.configurations?["int"])
        let boolean = jsonObj(config: split?.configurations?["boolean"])

        XCTAssertNotNil(split)
        XCTAssertEqual(20576.85, double?["c1"] as? Double)
        XCTAssertEqual("v1", string?["c1"] as? String)
        XCTAssertEqual(123456, int?["c1"] as? Int)
        XCTAssertEqual(false, boolean?["c1"] as? Bool)
    }

    func testEncodingNestedMultiConfig() {
        let config =
            "{\"treatment1\": \"{\\\"f1\\\": 10,\\\"f2\\\":\\\"v2\\\",\\\"nested1\\\":{\\\"nv1\\\":\\\"nval1\\\"}, \\\"nested2\\\":{\\\"nv2\\\":\\\"nval2\\\"}}\" , \"treatment2\": \"{\\\"f1\\\": 10.20,\\\"f2\\\":true,\\\"nested3\\\":{\\\"nested4\\\":{\\\"nv2\\\": \\\"nval3\\\"}}}\"}"
        let split = createAndParseSplit(config: config)
        let config1 = jsonObj(config: split?.configurations?["treatment1"])
        let config2 = jsonObj(config: split?.configurations?["treatment2"])
        let nested1 = config1?["nested1"] as? [String: Any]
        let nested2 = config1?["nested2"] as? [String: Any]
        let nested3 = config2?["nested3"] as? [String: Any]
        let nested4 = nested3?["nested4"] as? [String: Any]

        XCTAssertNotNil(split)
        XCTAssertEqual(10, config1?["f1"] as? Int)
        XCTAssertEqual("v2", config1?["f2"] as? String)

        XCTAssertNotNil(nested1)
        XCTAssertNotNil(nested2)
        XCTAssertNotNil(nested3)
        XCTAssertNotNil(nested4)

        XCTAssertEqual("nval1", nested1?["nv1"] as? String)
        XCTAssertEqual("nval1", nested1?["nv1"] as? String)
        XCTAssertEqual("nval2", nested2?["nv2"] as? String)
        XCTAssertEqual("nval3", nested4?["nv2"] as? String)

        XCTAssertEqual(10.20, config2?["f1"] as? Double)
        XCTAssertEqual(true, config2?["f2"] as? Bool)
    }

    func testEncodingNullConfig() {
        let split = createAndParseSplit(config: nil)

        XCTAssertNotNil(split)
        XCTAssertNil(split?.configurations)
    }

    func testDecodingSimpleConfig() {
        let config = "{ \"treatment1\": \"{\\\"c1\\\": \\\"v1\\\"}\", \"treatment2\": \"{\\\"c1\\\": \\\"v1\\\"}\"}"
        let initialSplit = createAndParseSplit(config: config)
        let jsonSplit = try? Json.encodeToJson(initialSplit)
        var split: Split?
        if let jsonSplit = jsonSplit {
            split = try? JSON.decodeFrom(json: jsonSplit, to: Split.self)
        }
        let t1Config = jsonObj(config: split?.configurations?["treatment1"])
        let t2Config = jsonObj(config: split?.configurations?["treatment2"])

        XCTAssertNotNil(split)
        XCTAssertNotNil(split?.configurations)
        XCTAssertEqual("v1", t1Config?["c1"] as? String)
        XCTAssertEqual("v1", t2Config?["c1"] as? String)
    }

    func testDecodingArrayAndMapConfig() {
        let config =
            "{ \"treatment1\": \"{\\\"c1\\\": \\\"v1\\\"}\", \"treatment2\": \"{\\\"a1\\\": [1,2,3,4], \\\"m1\\\": {\\\"c1\\\": \\\"v1\\\"}}\"}"
        let initialSplit = createAndParseSplit(config: config)
        let jsonSplit = try? Json.encodeToJson(initialSplit)
        var split: Split?
        if let jsonSplit = jsonSplit {
            split = try? JSON.decodeFrom(json: jsonSplit, to: Split.self)
        }
        let t1Config = jsonObj(config: split?.configurations?["treatment1"])
        let t2Config = jsonObj(config: split?.configurations?["treatment2"])
        let array = t2Config?["a1"] as? [Int]
        let map = t2Config?["m1"] as? [String: String]

        XCTAssertNotNil(split)
        XCTAssertNotNil(split?.configurations)
        XCTAssertNotNil(t1Config)
        XCTAssertNotNil(t2Config)
        XCTAssertNotNil(array)
        XCTAssertNotNil(map)
        XCTAssertEqual("v1", t1Config?["c1"] as? String)
        XCTAssertEqual(4, array?.count)
        XCTAssertEqual(1, array?[0])
        XCTAssertEqual(4, array?[3])
        XCTAssertEqual("v1", map?["c1"])
    }

    private func createAndParseSplit(config: String?) -> Split? {
        var jsonSplit = "\"name\":\"TEST_FEATURE\""
        if let config = config {
            jsonSplit = "\(jsonSplit), \"configurations\":\(config)"
        }
        jsonSplit = "{\(jsonSplit)}"
        let split = try? JSON.decodeFrom(json: jsonSplit, to: Split.self)
        return split
    }

    private func jsonObj(config: String?) -> [String: Any]? {
        var res: [String: Any]? = nil
        if let config = config, let data = config.data(using: .utf8) {
            do {
                res = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            } catch {}
        }
        return res
    }
}
