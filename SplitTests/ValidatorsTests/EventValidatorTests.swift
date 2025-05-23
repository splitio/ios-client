//
//  EventValidatorTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 22/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class EventValidatorTests: XCTestCase {

    var validator: EventValidator!

    override func setUp() {
        let split1 = newSplit(trafficType: "custom")
        let split2 = newSplit(trafficType: "other")
        let split3 = newSplit(trafficType: "archivedtraffictype", status: .archived)

        let splitsStorage = SplitsStorageStub()
        _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: [split1, split2],
                                                                   archivedSplits: [split3],
                                                                   changeNumber: 100,
                                                                   updateTimestamp: 100))
        validator = DefaultEventValidator(splitsStorage: splitsStorage)
    }

    override func tearDown() {
    }

    func testValidEventAllValues() {
        XCTAssertNil(validator.validate(key: "key", trafficTypeName: "custom", eventTypeId: "type1", value: 1.0, properties: nil, isSdkReady: true))
    }

    func testValidEventNullValue() {
        XCTAssertNil(validator.validate(key: "key", trafficTypeName: "custom", eventTypeId: "type1", value: nil, properties: nil, isSdkReady: true))
    }

    func testNullKey() {
        let errorInfo = validator.validate(key: nil, trafficTypeName: "custom", eventTypeId: "type1", value: nil, properties: nil, isSdkReady: true)
        XCTAssertNotNil(errorInfo)
        XCTAssertTrue(errorInfo?.isError ?? false)
        XCTAssertEqual("you passed a null key, the key must be a non-empty string", errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }

    func testEmptyKey() {
        let errorInfo = validator.validate(key: "", trafficTypeName: "custom", eventTypeId: "type1", value: nil, properties: nil, isSdkReady: true)
        XCTAssertNotNil(errorInfo)
        XCTAssertTrue(errorInfo?.isError ?? false)
        XCTAssertEqual("you passed an empty string, matching key must a non-empty string", errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }

    func testLongKey() {
        let key = String(repeating: "p", count: 300)
        let errorInfo = validator.validate(key: key, trafficTypeName: "custom", eventTypeId: "type1", value: nil, properties: nil, isSdkReady: true)
        XCTAssertNotNil(errorInfo)
        XCTAssertTrue(errorInfo?.isError ?? false)
        XCTAssertEqual("matching key too long - must be \(ValidationConfig.default.maximumKeyLength) characters or less", errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }

    func testNullType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nil, value: nil, properties: nil, isSdkReady: true)
        XCTAssertNotNil(errorInfo)
        XCTAssertTrue(errorInfo?.isError ?? false)
        XCTAssertEqual("you passed a null or undefined event_type, event_type must be a non-empty String", errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }

    func testEmptyType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: "", value: nil, properties: nil, isSdkReady: true)
        XCTAssertNotNil(errorInfo)
        XCTAssertTrue(errorInfo?.isError ?? false)
        XCTAssertEqual("you passed an empty event_type, event_type must be a non-empty String", errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }

    func testTypeName() {

        let nameHelper = EventTypeNameHelper()
        let errorInfo1 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.validAllValidChars, value: nil, properties: nil, isSdkReady: true)
        let errorInfo2 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.validStartNumber, value: nil, properties: nil, isSdkReady: true)
        let errorInfo3 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.invalidChars, value: nil, properties: nil, isSdkReady: true)
        let errorInfo4 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.invalidUndercoreStart, value: nil, properties: nil, isSdkReady: true)
        let errorInfo5 = validator.validate(key: "key1", trafficTypeName: "custom", eventTypeId: nameHelper.invalidHypenStart, value: nil, properties: nil, isSdkReady: true)


        XCTAssertNil(errorInfo1)
        XCTAssertNil(errorInfo2)

        XCTAssertNotNil(errorInfo3)
        XCTAssertTrue(errorInfo3?.isError ?? false)
        XCTAssertEqual(errorMessage(for: nameHelper.invalidChars), errorInfo3?.errorMessage)
        XCTAssertEqual(errorInfo3?.warnings.count, 0)

        XCTAssertNotNil(errorInfo4)
        XCTAssertTrue(errorInfo4?.isError ?? false)
        XCTAssertEqual(errorMessage(for: nameHelper.invalidUndercoreStart), errorInfo4?.errorMessage)
        XCTAssertEqual(errorInfo4?.warnings.count, 0)

        XCTAssertNotNil(errorInfo5)
        XCTAssertTrue(errorInfo5?.isError ?? false)
        XCTAssertEqual(errorMessage(for: nameHelper.invalidHypenStart), errorInfo5?.errorMessage)
        XCTAssertEqual(errorInfo5?.warnings.count, 0)

    }

    func testNullTrafficType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: nil, eventTypeId: "type1", value: nil, properties: nil, isSdkReady: true)
        XCTAssertNotNil(errorInfo)
        XCTAssertTrue(errorInfo?.isError ?? false)
        XCTAssertEqual("you passed a null or undefined traffic_type_name, traffic_type_name must be a non-empty string", errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }

    func testEmptyTrafficType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: "", eventTypeId: "type1", value: nil, properties: nil, isSdkReady: true)
        XCTAssertNotNil(errorInfo)
        XCTAssertTrue(errorInfo?.isError ?? false)
        XCTAssertEqual("you passed an empty traffic_type_name, traffic_type_name must be a non-empty string", errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 0)
    }

    func testUppercaseCharsInTrafficType() {

        let upperCaseMsg = "traffic_type_name should be all lowercase - converting string to lowercase"

        let errorInfo1 = validator.validate(key: "key1", trafficTypeName: "Custom", eventTypeId: "type1", value: nil, properties: nil, isSdkReady: true)
        let errorInfo2 = validator.validate(key: "key1", trafficTypeName: "cUSTom", eventTypeId: "type1", value: nil, properties: nil, isSdkReady: true)
        let errorInfo3 = validator.validate(key: "key1", trafficTypeName: "custoM", eventTypeId: "type1", value: nil, properties: nil, isSdkReady: true)

        XCTAssertNotNil(errorInfo1)
        XCTAssertFalse(errorInfo1?.isError ?? true)
        XCTAssertEqual(upperCaseMsg, errorInfo1?.warnings.values.map ({$0})[0])
        XCTAssertEqual(errorInfo1?.warnings.count, 1)
        XCTAssertTrue(errorInfo1?.hasWarning(.trafficTypeNameHasUppercaseChars) ?? false)

        XCTAssertNotNil(errorInfo2)
        XCTAssertFalse(errorInfo2?.isError ?? true)
        XCTAssertEqual(upperCaseMsg, errorInfo2?.warnings.values.map ({$0})[0])
        XCTAssertEqual(errorInfo2?.warnings.count, 1)
        XCTAssertTrue(errorInfo2?.hasWarning(.trafficTypeNameHasUppercaseChars) ?? false)

        XCTAssertNotNil(errorInfo3)
        XCTAssertFalse(errorInfo3?.isError ?? true)
        XCTAssertEqual(upperCaseMsg, errorInfo3?.warnings.values.map ({$0})[0])
        XCTAssertEqual(errorInfo3?.warnings.count, 1)
        XCTAssertTrue(errorInfo3?.hasWarning(.trafficTypeNameHasUppercaseChars) ?? false)
    }

    func testNoChachedServerTrafficType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: "nocached", eventTypeId: "type1", value: nil, properties: nil, isSdkReady: true)
        XCTAssertNotNil(errorInfo)
        XCTAssertNil(errorInfo?.error)
        XCTAssertNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 1)
        XCTAssertEqual("traffic_type_name nocached does not have any corresponding feature flags in this environment, make sure you’re tracking your events to a valid traffic type defined in the Split user interface", errorInfo?.warnings.values.map ({$0})[0])
        XCTAssertTrue(errorInfo?.hasWarning(.trafficTypeWithoutSplitInEnvironment) ?? false)
    }

    func testNoChachedServerAndUppercasedTrafficType() {
        let errorInfo = validator.validate(key: "key1", trafficTypeName: "noCached", eventTypeId: "type1", value: nil, properties: nil, isSdkReady: true)
        XCTAssertNotNil(errorInfo)
        XCTAssertNil(errorInfo?.error)
        XCTAssertNil(errorInfo?.errorMessage)
        XCTAssertEqual(errorInfo?.warnings.count, 2)
        XCTAssertTrue(errorInfo?.hasWarning(.trafficTypeWithoutSplitInEnvironment) ?? false)
        XCTAssertTrue(errorInfo?.hasWarning(.trafficTypeNameHasUppercaseChars) ?? false)
        XCTAssertEqual("traffic_type_name should be all lowercase - converting string to lowercase", errorInfo?.warnings[.trafficTypeNameHasUppercaseChars])
        XCTAssertEqual("traffic_type_name noCached does not have any corresponding feature flags in this environment, make sure you’re tracking your events to a valid traffic type defined in the Split user interface", errorInfo?.warnings[.trafficTypeWithoutSplitInEnvironment])


    }

    private func newSplit(trafficType: String, status: Status = .active) -> Split {
        let split = SplitTestHelper.newSplit(name: UUID().uuidString, trafficType: trafficType)
        split.status = status
        split.isCompletelyParsed = true
        return split
    }

    private func errorMessage(for typeName: String) -> String {
        return "you passed \(typeName), event name must adhere to the regular expression \(ValidationConfig.default.trackEventNamePattern). This means an event name must be alphanumeric, cannot be more than 80 characters long, and can only include a dash, underscore, period, or colon as separators of alphanumeric characters"
    }

}
