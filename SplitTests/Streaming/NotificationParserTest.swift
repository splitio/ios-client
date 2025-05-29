//
//  NotificationParserTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 12/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class NotificationParserTest: XCTestCase {
    let notificationParser = DefaultSseNotificationParser()

    static let kMySegmentsChannel = "MzM5Njc0ODcyNg==_MTExMzgwNjgx_MTcwNTI2MTM0Mg==_memberships"

    let splitsChangeNotificationMessage = """
    {\"id\":\"VSEQrcq9D8:0:0\",\"clientId\":\"NDEzMTY5Mzg0MA==:MjU4MzkwNDA2NA==\",\"timestamp\":1584554772719,\"encoding\":\"json\",\"channel\":\"MzM5Njc0ODcyNg==_MTExMzgwNjgx_splits\",\"data\":\"{\\\"type\\\":\\\"SPLIT_UPDATE\\\",\\\"changeNumber\\\":1584554772108}\"}
    """

    let splitsChangeNotificationMessageWithPayload = """
    {\"id\":\"VSEQrcq9D8:0:0\",\"clientId\":\"NDEzMTY5Mzg0MA==:MjU4MzkwNDA2NA==\",\"timestamp\":1584554772719,\"encoding\":\"json\",\"channel\":\"MzM5Njc0ODcyNg==_MTExMzgwNjgx_splits\",\"data\":\"{\\\"type\\\":\\\"SPLIT_UPDATE\\\",\\\"changeNumber\\\":1584554772108 ,\\\"pcn\\\":0,\\\"c\\\":1, \\\"d\\\":\\\"H4sIAAAAAAAA/8yT327aTBDFXyU612vJxoTgvUMfKB8qcaSapqoihAZ7DNusvWi9TpUiv3tl/pdQVb1qL+cwc3bOj/EGzlKeq3T6tuaYCoZEXbGFgMogkXXDIM0y31v4C/aCgMnrU9/3gl7Pp4yilMMIAuVusqDamvlXeiWIg/FAa5OSU6aEDHz/ip4wZ5Be1AmjoBsFAtVOCO56UXh31/O7ApUjV1eQGPw3HT+NIPCitG7bctIVC2ScU63d1DK5gksHCZPnEEhXVC45rosFW8ig1++GYej3g85tJEB6aSA7Aqkpc7Ws7XahCnLTbLVM7evnzalsUUHi8//j6WgyTqYQKMilK7b31tRryLa3WKiyfRCDeHhq2Dntiys+JS/J8THUt5VyrFXlHnYTQ3LU2h91yGdQVqhy+0RtTeuhUoNZ08wagTVZdxbBndF5vYVApb7z9m9pZgKaFqwhT+6coRHvg398nEweP/157Bd+S1hz6oxtm88O73B0jbhgM47nyej+YRRfgdNODDlXJWcJL9tUF5SqnRqfbtPr4LdcTHnk4rfp3buLOkG7+Pmp++vRM9w/wVblzX7Pm8OGfxf5YDKZfxh9SS6B/2Pc9t/7ja01o5k1PwIAAP//uTipVskEAAA=\\\"}\"}
    """
    let occupancyNotificationMessage = """
     {\"id\":\"x2dE2TEiJL:0:0\",\"clientId\":\"NDEzMTY5Mzg0MA==:OTc5Nzc4NDYz\",\"timestamp\":1584647533288,\"encoding\":\"json\",\"channel\":\"control_pri\",\"data\":\"{\\\"metrics\\\": {\\\"publishers\\\":1}}\"}
    """

    let controlNotificationMessage = """
     {\"id\":\"x2dE2TEiJL:0:0\",\"clientId\":\"NDEzMTY5Mzg0MA==:OTc5Nzc4NDYz\",\"timestamp\":1584647533288,\"encoding\":\"json\",\"channel\":\"control_pri\",\"data\":\"{\\\"type\\\":\\\"CONTROL\\\",\\\"controlType\\\":\\\"STREAMING_RESUMED\\\"}\"}
    """

    let errorNotificationMessage = """
    {\"id\":\"null\",\"name\":\"error\",\"comment\":\"[no comments]\",\"data\":\"{\\\"message\\\":\\\"Invalid token capability must be a string\\\",\\\"code\\\":40144,\\\"statusCode\\\":400,\\\"href\\\":\\\"https://help.ably.io/error/40144\\\"}\"}
    """
    let splitKillNotificationMessage = """
    {\"id\":\"-OT-rGuSwz:0:0\",\"clientId\":\"NDEzMTY5Mzg0MA==:NDIxNjU0NTUyNw==\",\"timestamp\":1584647606489,\"encoding\":\"json\",\"channel\":\"MzM5Njc0ODcyNg==_MTExMzgwNjgx_splits\",\"data\":\"{\\\"type\\\":\\\"SPLIT_KILL\\\",\\\"changeNumber\\\":1584647606125,\\\"defaultTreatment\\\":\\\"off\\\",\\\"splitName\\\":\\\"dep_split\\\"}\"}
    """

    override func setUp() {}

    func testProcessSplitUpdate() throws {
        let incoming = notificationParser.parseIncoming(jsonString: splitsChangeNotificationMessage)
        let splitUpdate = try notificationParser.parseTargetingRuleNotification(
            jsonString: incoming!.jsonData!,
            type: .splitUpdate)

        XCTAssertEqual(NotificationType.splitUpdate, incoming?.type)
        XCTAssertEqual(1584554772108, splitUpdate.changeNumber)
    }

    func testProcessSplitUpdateWithPayload() throws {
        let incoming = notificationParser.parseIncoming(jsonString: splitsChangeNotificationMessageWithPayload)
        let splitUpdate = try notificationParser.parseTargetingRuleNotification(
            jsonString: incoming!.jsonData!,
            type: .splitUpdate)

        XCTAssertEqual(NotificationType.splitUpdate, incoming?.type)
        XCTAssertEqual(1584554772108, splitUpdate.changeNumber)
        XCTAssertEqual(0, splitUpdate.previousChangeNumber)
        XCTAssertEqual(CompressionType.gzip, splitUpdate.compressionType)
        XCTAssertNotNil(splitUpdate.definition)
    }

    func testProcessSplitKill() throws {
        let incoming = notificationParser.parseIncoming(jsonString: splitKillNotificationMessage)
        let splitKill = try notificationParser.parseSplitKill(jsonString: incoming!.jsonData!)

        XCTAssertEqual(NotificationType.splitKill, incoming?.type)
        XCTAssertEqual("dep_split", splitKill.splitName)
        XCTAssertEqual("off", splitKill.defaultTreatment)
    }

    func testProcessMySegmentUpdateUnbounded() throws {
        let json = TestingData.membershipsNotificationUnboundedMessage(type: .mySegmentsUpdate)
        let incoming = notificationParser.parseIncoming(jsonString: json)
        let mySegmentUpdate = try notificationParser.parseMembershipsUpdate(
            jsonString: incoming!.jsonData!,
            type: .mySegmentsUpdate)

        XCTAssertEqual(NotificationType.mySegmentsUpdate, incoming?.type)
        XCTAssertEqual(.unboundedFetchRequest, mySegmentUpdate.updateStrategy)
        XCTAssertNil(mySegmentUpdate.changeNumber)
        XCTAssertNil(mySegmentUpdate.data)
        XCTAssertNil(mySegmentUpdate.segments)
    }

    func testProcessMySegmentUpdateRemoval() throws {
        let json = TestingData.membershipsNotificationSegmentRemovalMessage(type: .mySegmentsUpdate)
        let incoming = notificationParser.parseIncoming(jsonString: json)
        let mySegmentUpdate = try notificationParser.parseMembershipsUpdate(
            jsonString: incoming!.jsonData!,
            type: .mySegmentsUpdate)

        XCTAssertEqual(NotificationType.mySegmentsUpdate, incoming?.type)
        XCTAssertEqual(.segmentRemoval, mySegmentUpdate.updateStrategy)
        XCTAssertNil(mySegmentUpdate.changeNumber)
        XCTAssertNil(mySegmentUpdate.data)
        XCTAssertEqual(["android_test", "ios_test"], mySegmentUpdate.segments)
    }

    func testProcessMySegmentUpdateAllFields() throws {
        let json = TestingData.membershipsNotificationAllFieldsMessage(type: .mySegmentsUpdate)
        let incoming = notificationParser.parseIncoming(jsonString: json)
        let mySegmentUpdate = try notificationParser.parseMembershipsUpdate(
            jsonString: incoming!.jsonData!,
            type: .myLargeSegmentsUpdate)

        XCTAssertEqual(NotificationType.mySegmentsUpdate, incoming?.type)
        XCTAssertEqual(.unboundedFetchRequest, mySegmentUpdate.updateStrategy)
        XCTAssertNil(mySegmentUpdate.changeNumber)
        XCTAssertEqual(["test"], mySegmentUpdate.segments)
        XCTAssertEqual(
            "eJwEwLsRwzAMA9BdWKsg+IFBraJTkRXS5rK7388+tg+KdC8+jq4eBBQLFcUnO8FAAC36gndOSEyFqJFP32Vf2+f+3wAAAP//hUQQ9A==",
            mySegmentUpdate.data)
        XCTAssertNil(mySegmentUpdate.hash)
        XCTAssertNil(mySegmentUpdate.seed)
        XCTAssertNil(mySegmentUpdate.timeMillis)
    }

    func testProcessMyLargeSegmentUpdateUnbounded() throws {
        let json = TestingData.membershipsNotificationUnboundedMessage(type: .myLargeSegmentsUpdate)
        let incoming = notificationParser.parseIncoming(jsonString: json)
        let mySegmentUpdate = try notificationParser.parseMembershipsUpdate(
            jsonString: incoming!.jsonData!,
            type: .myLargeSegmentsUpdate)

        XCTAssertEqual(NotificationType.myLargeSegmentsUpdate, incoming?.type)
        XCTAssertEqual(.unboundedFetchRequest, mySegmentUpdate.updateStrategy)
        XCTAssertEqual(1702507130121, mySegmentUpdate.changeNumber)
        XCTAssertNil(mySegmentUpdate.data)
        XCTAssertNil(mySegmentUpdate.segments)
        XCTAssertNil(mySegmentUpdate.hash)
        XCTAssertNil(mySegmentUpdate.seed)
        XCTAssertEqual(mySegmentUpdate.timeMillis, 100)
    }

    func testProcessMyLargeSegmentUpdateRemoval() throws {
        let json = TestingData.membershipsNotificationSegmentRemovalMessage(type: .myLargeSegmentsUpdate)
        let incoming = notificationParser.parseIncoming(jsonString: json)
        let mySegmentUpdate = try notificationParser.parseMembershipsUpdate(
            jsonString: incoming!.jsonData!,
            type: .myLargeSegmentsUpdate)

        XCTAssertEqual(NotificationType.myLargeSegmentsUpdate, incoming?.type)
        XCTAssertEqual(.segmentRemoval, mySegmentUpdate.updateStrategy)
        XCTAssertEqual(1702507130121, mySegmentUpdate.changeNumber)
        XCTAssertEqual(["android_test", "ios_test"], mySegmentUpdate.segments?.sorted())
        XCTAssertNil(mySegmentUpdate.data)
        XCTAssertNil(mySegmentUpdate.hash)
        XCTAssertNil(mySegmentUpdate.seed)
        XCTAssertNil(mySegmentUpdate.timeMillis)
    }

    func testProcessMyLargeSegmentUpdateAllFields() throws {
        let json = TestingData.membershipsNotificationAllFieldsMessage(type: .myLargeSegmentsUpdate)
        let incoming = notificationParser.parseIncoming(jsonString: json)
        let mySegmentUpdate = try notificationParser.parseMembershipsUpdate(
            jsonString: incoming!.jsonData!,
            type: .myLargeSegmentsUpdate)

        XCTAssertEqual(NotificationType.myLargeSegmentsUpdate, incoming?.type)
        XCTAssertEqual(.unboundedFetchRequest, mySegmentUpdate.updateStrategy)
        XCTAssertEqual(1702507130121, mySegmentUpdate.changeNumber)
        XCTAssertEqual(["test"], mySegmentUpdate.segments)
        XCTAssertEqual(
            "eJwEwLsRwzAMA9BdWKsg+IFBraJTkRXS5rK7388+tg+KdC8+jq4eBBQLFcUnO8FAAC36gndOSEyFqJFP32Vf2+f+3wAAAP//hUQQ9A==",
            mySegmentUpdate.data)
        XCTAssertEqual(FetchDelayAlgo.none, mySegmentUpdate.hash)
        XCTAssertEqual(200, mySegmentUpdate.seed)
        XCTAssertEqual(300, mySegmentUpdate.timeMillis)
    }

    func testProcessOccupancy() throws {
        let incoming = notificationParser.parseIncoming(jsonString: occupancyNotificationMessage)

        let notification = try notificationParser.parseOccupancy(
            jsonString: incoming!.jsonData!,
            timestamp: 5,
            channel: "control_pri")

        XCTAssertEqual(NotificationType.occupancy, notification.type)
        XCTAssertEqual(1, notification.metrics.publishers)
        XCTAssertEqual(5, notification.timestamp)
    }

    func testProcessControl() throws {
        let incoming = notificationParser.parseIncoming(jsonString: controlNotificationMessage)
        let notification = try notificationParser.parseControl(jsonString: incoming!.jsonData!)

        XCTAssertEqual(NotificationType.control, notification.type)
        XCTAssertEqual(ControlNotification.ControlType.streamingResumed, notification.controlType)
    }

    func testProcessError() {
        let incoming = notificationParser.parseIncoming(jsonString: errorNotificationMessage)

        XCTAssertEqual(NotificationType.sseError, incoming?.type)
    }

    func testExtractUserKeyHashFromChannel() {
        let expectedResult = "MTcwNTI2MTM0Mg=="

        let result = notificationParser.extractUserKeyHashFromChannel(channel: Self.kMySegmentsChannel)

        XCTAssertEqual(expectedResult, result)
    }
}
