//
//  NotificationParserTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 12/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class NotificationParserTest: XCTestCase {

    let notificationParser = DefaultSseNotificationParser()

    static let kMySegmentsChannel = "MzM5Njc0ODcyNg==_MTExMzgwNjgx_MTcwNTI2MTM0Mg==_mySegments"

    let splitsChangeNotificationMessage = """
{\"id\":\"VSEQrcq9D8:0:0\",\"clientId\":\"NDEzMTY5Mzg0MA==:MjU4MzkwNDA2NA==\",\"timestamp\":1584554772719,\"encoding\":\"json\",\"channel\":\"MzM5Njc0ODcyNg==_MTExMzgwNjgx_splits\",\"data\":\"{\\\"type\\\":\\\"SPLIT_UPDATE\\\",\\\"changeNumber\\\":1584554772108}\"}
"""

    let splitsChangeNotificationMessageWithPayload = """
{\"id\":\"VSEQrcq9D8:0:0\",\"clientId\":\"NDEzMTY5Mzg0MA==:MjU4MzkwNDA2NA==\",\"timestamp\":1584554772719,\"encoding\":\"json\",\"channel\":\"MzM5Njc0ODcyNg==_MTExMzgwNjgx_splits\",\"data\":\"{\\\"type\\\":\\\"SPLIT_UPDATE\\\",\\\"changeNumber\\\":1584554772108 ,\\\"pcn\\\":0,\\\"c\\\":1, \\\"d\\\":\\\"H4sIAAAAAAAA/8yT327aTBDFXyU612vJxoTgvUMfKB8qcaSapqoihAZ7DNusvWi9TpUiv3tl/pdQVb1qL+cwc3bOj/EGzlKeq3T6tuaYCoZEXbGFgMogkXXDIM0y31v4C/aCgMnrU9/3gl7Pp4yilMMIAuVusqDamvlXeiWIg/FAa5OSU6aEDHz/ip4wZ5Be1AmjoBsFAtVOCO56UXh31/O7ApUjV1eQGPw3HT+NIPCitG7bctIVC2ScU63d1DK5gksHCZPnEEhXVC45rosFW8ig1++GYej3g85tJEB6aSA7Aqkpc7Ws7XahCnLTbLVM7evnzalsUUHi8//j6WgyTqYQKMilK7b31tRryLa3WKiyfRCDeHhq2Dntiys+JS/J8THUt5VyrFXlHnYTQ3LU2h91yGdQVqhy+0RtTeuhUoNZ08wagTVZdxbBndF5vYVApb7z9m9pZgKaFqwhT+6coRHvg398nEweP/157Bd+S1hz6oxtm88O73B0jbhgM47nyej+YRRfgdNODDlXJWcJL9tUF5SqnRqfbtPr4LdcTHnk4rfp3buLOkG7+Pmp++vRM9w/wVblzX7Pm8OGfxf5YDKZfxh9SS6B/2Pc9t/7ja01o5k1PwIAAP//uTipVskEAAA=\\\"}\"}
"""

    let mySegmentsUpdateNotificationMessage = """
 {\"id\":\"x2dE2TEiJL:0:0\",\"clientId\":\"NDEzMTY5Mzg0MA==:OTc5Nzc4NDYz\",\"timestamp\":1584647533288,\"encoding\":\"json\",\"channel\":\"\(kMySegmentsChannel)\",\"data\":\"{\\\"type\\\":\\\"MY_SEGMENTS_UPDATE\\\",\\\"changeNumber\\\":1584647532812,\\\"includesPayload\\\":false}\"}
"""

    let splitKillNotificationMessage = """
 {\"id\":\"-OT-rGuSwz:0:0\",\"clientId\":\"NDEzMTY5Mzg0MA==:NDIxNjU0NTUyNw==\",\"timestamp\":1584647606489,\"encoding\":\"json\",\"channel\":\"MzM5Njc0ODcyNg==_MTExMzgwNjgx_splits\",\"data\":\"{\\\"type\\\":\\\"SPLIT_KILL\\\",\\\"changeNumber\\\":1584647606125,\\\"defaultTreatment\\\":\\\"off\\\",\\\"splitName\\\":\\\"dep_split\\\"}\"}
"""

    let mySegmentUpdateInlineNotificationMessage = """
 {\"id\":\"x2dE2TEiJL:0:0\",\"clientId\":\"NDEzMTY5Mzg0MA==:OTc5Nzc4NDYz\",\"timestamp\":1584647533288,\"encoding\":\"json\",\"channel\":\"\(kMySegmentsChannel)\",\"data\":\"{\\\"type\\\":\\\"MY_SEGMENTS_UPDATE\\\",\\\"changeNumber\\\":1584647532812,\\\"includesPayload\\\":true,\\\"segmentList\\\":[\\\"segment1\\\", \\\"segment2\\\"]}\"}
"""
    let mySegmentsUpdateV2NotificationUnboundedMessage = """
 {\"id\":\"x2dE2TEiJL:0:0\",\"clientId\":\"NDEzMTY5Mzg0MA==:OTc5Nzc4NDYz\",\"timestamp\":1584647533288,\"encoding\":\"json\",\"channel\":\"\(kMySegmentsChannel)\",\"data\": \"{\\\"type\\\": \\\"MY_SEGMENTS_UPDATE_V2\\\", \\"u\\": 0, \\"c\\": 0}\"}
"""

    let mySegmentsUpdateV2NotificationSegmentRemovalMessage = """
 {\"id\":\"x2dE2TEiJL:0:0\",\"clientId\":\"NDEzMTY5Mzg0MA==:OTc5Nzc4NDYz\",\"timestamp\":1584647533288,\"encoding\":\"json\",\"channel\":\"\(kMySegmentsChannel)\",\"data\": \"{\\\"type\\\": \\\"MY_SEGMENTS_UPDATE_V2\\\", \\"u\\": 3, \\"c\\": 0, \\"segmentName\\":\\"segment_remove\\"}\"}
"""

    let myLargeSegmentsUpdateNotificationUnboundedMessage = """
    {
      \"id\": \"diSrQttrC9:0:0\",
      \"clientId\": \"pri:MjcyNDE2NDUxMA==\",
      \"timestamp\": 1702507131100,
      \"encoding\": \"json\",
      \"channel\": \"NzM2MDI5Mzc0_MTc1MTYwODQxMQ==_mylargesegments\",
      \"data\": \"{\\\"type\\\":\\\"MY_LARGE_SEGMENTS_UPDATE\\\",\\\"changeNumber\\\":1702507130121,\\\"c\\\":2,\\\"u\\\":0, \\\"i\\\": 100}\"
    }
"""

    let myLargeSegmentsUpdateNotificationSegmentRemovalMessage = """
    {
      \"id\": \"diSrQttrC9:0:0\",
      \"clientId\": \"pri:MjcyNDE2NDUxMA==\",
      \"timestamp\": 1702507131100,
      \"encoding\": \"json\",
      \"channel\": \"NzM2MDI5Mzc0_MTc1MTYwODQxMQ==_mylargesegments\",
      \"data\": \"{\\\"type\\\":\\\"MY_LARGE_SEGMENTS_UPDATE\\\",\\\"changeNumber\\\":1702507130121,\\\"u\\\":3,\\\"c\\\":0, \\\"largeSegments\\\":[\\\"android_test\\\", \\\"ios_test\\\"]}\"
    }
"""

    let myLargeSegmentsUpdateNotificationAllFieldsMessage = """
    {
      \"id\": \"diSrQttrC9:0:0\",
      \"clientId\": \"pri:MjcyNDE2NDUxMA==\",
      \"timestamp\": 1702507131100,
      \"encoding\": \"json\",
      \"channel\": \"NzM2MDI5Mzc0_MTc1MTYwODQxMQ==_mylargesegments\",
      \"data\": \"{\\\"type\\\":\\\"MY_LARGE_SEGMENTS_UPDATE\\\",\\\"changeNumber\\\":1702507130121,\\\"c\\\":2,\\\"s\\\":200,\\\"u\\\":0,\\\"h\\\":100,\\\"i\\\": 300,\\\"largeSegments\\\": [\\\"test\\\"], \\\"d\\\":\\\"eJwEwLsRwzAMA9BdWKsg+IFBraJTkRXS5rK7388+tg+KdC8+jq4eBBQLFcUnO8FAAC36gndOSEyFqJFP32Vf2+f+3wAAAP//hUQQ9A==\\\"}\"
    }
"""

    let occupancyNotificationMessage = """
 {\"id\":\"x2dE2TEiJL:0:0\",\"clientId\":\"NDEzMTY5Mzg0MA==:OTc5Nzc4NDYz\",\"timestamp\":1584647533288,\"encoding\":\"json\",\"channel\":\"control_pri\",\"data\":\"{\\\"metrics\\\": {\\\"publishers\\\":1}}\"}
"""

    let controlNotificationMessage = """
 {\"id\":\"x2dE2TEiJL:0:0\",\"clientId\":\"NDEzMTY5Mzg0MA==:OTc5Nzc4NDYz\",\"timestamp\":1584647533288,\"encoding\":\"json\",\"channel\":\"control_pri\",\"data\":\"{\\\"type\\\":\\\"CONTROL\\\",\\\"controlType\\\":\\\"STREAMING_RESUMED\\\"}\"}
"""

    let errorNotificationMessage = """
{\"id\":\"null\",\"name\":\"error\",\"comment\":\"[no comments]\",\"data\":\"{\\\"message\\\":\\\"Invalid token; capability must be a string\\\",\\\"code\\\":40144,\\\"statusCode\\\":400,\\\"href\\\":\\\"https://help.ably.io/error/40144\\\"}\"}
"""

    override func setUp() {
    }

    func testProcessSplitUpdate() throws {
        let incoming = notificationParser.parseIncoming(jsonString: splitsChangeNotificationMessage);
        let splitUpdate = try notificationParser.parseSplitUpdate(jsonString: incoming!.jsonData!);

        XCTAssertEqual(NotificationType.splitUpdate, incoming?.type);
        XCTAssertEqual(1584554772108, splitUpdate.changeNumber);
    }

    func testProcessSplitUpdateWithPayload() throws {
        let incoming = notificationParser.parseIncoming(jsonString: splitsChangeNotificationMessageWithPayload);
        let splitUpdate = try notificationParser.parseSplitUpdate(jsonString: incoming!.jsonData!);

        XCTAssertEqual(NotificationType.splitUpdate, incoming?.type);
        XCTAssertEqual(1584554772108, splitUpdate.changeNumber);
        XCTAssertEqual(0, splitUpdate.previousChangeNumber);
        XCTAssertEqual(CompressionType.gzip, splitUpdate.compressionType);
        XCTAssertNotNil(splitUpdate.definition);

    }


    func testProcessSplitKill() throws {
        let incoming = notificationParser.parseIncoming(jsonString: splitKillNotificationMessage);
        let splitKill = try notificationParser.parseSplitKill(jsonString: incoming!.jsonData!);

        XCTAssertEqual(NotificationType.splitKill, incoming?.type);
        XCTAssertEqual("dep_split", splitKill.splitName);
        XCTAssertEqual("off", splitKill.defaultTreatment);
    }


    func testProcessMySegmentUpdate() throws {
        let incoming = notificationParser.parseIncoming(jsonString: mySegmentsUpdateNotificationMessage);
        let mySegmentUpdate = try notificationParser.parseMySegmentUpdate(jsonString: incoming!.jsonData!,
                                                                          channel: Self.kMySegmentsChannel)

        XCTAssertEqual(NotificationType.mySegmentsUpdate, incoming?.type);
        XCTAssertEqual(1584647532812, mySegmentUpdate.changeNumber);
        XCTAssertFalse(mySegmentUpdate.includesPayload);
    }


    func testProcessMySegmentUpdateInline() throws {
        let incoming = notificationParser.parseIncoming(jsonString: mySegmentUpdateInlineNotificationMessage)
        let mySegmentUpdate = try notificationParser.parseMySegmentUpdate(jsonString: incoming!.jsonData!,
                                                                          channel: Self.kMySegmentsChannel)

        XCTAssertEqual(NotificationType.mySegmentsUpdate, incoming?.type);
        XCTAssertEqual(1584647532812, mySegmentUpdate.changeNumber);
        XCTAssertTrue(mySegmentUpdate.includesPayload)
        XCTAssertEqual(2, mySegmentUpdate.segmentList?.count);
        XCTAssertEqual(1, mySegmentUpdate.segmentList?.filter { $0 == "segment1"}.count)
        XCTAssertEqual(1, mySegmentUpdate.segmentList?.filter { $0 == "segment2"}.count)
    }

    func testProcessMySegmentUpdateV2Unbounded() throws {
        let incoming = notificationParser.parseIncoming(jsonString: mySegmentsUpdateV2NotificationUnboundedMessage);
        let mySegmentUpdate = try notificationParser.parseMySegmentUpdateV2(jsonString: incoming!.jsonData!);

        XCTAssertEqual(NotificationType.mySegmentsUpdateV2, incoming?.type);
        XCTAssertEqual(.unboundedFetchRequest, mySegmentUpdate.updateStrategy);
        XCTAssertNil(mySegmentUpdate.changeNumber)
        XCTAssertNil(mySegmentUpdate.data)
        XCTAssertNil(mySegmentUpdate.segmentName)
    }

    func testProcessMySegmentUpdateV2Removal() throws {
        let incoming = notificationParser.parseIncoming(jsonString: mySegmentsUpdateV2NotificationSegmentRemovalMessage);
        let mySegmentUpdate = try notificationParser.parseMySegmentUpdateV2(jsonString: incoming!.jsonData!);

        XCTAssertEqual(NotificationType.mySegmentsUpdateV2, incoming?.type);
        XCTAssertEqual(.segmentRemoval, mySegmentUpdate.updateStrategy);
        XCTAssertNil(mySegmentUpdate.changeNumber)
        XCTAssertNil(mySegmentUpdate.data)
        XCTAssertEqual("segment_remove", mySegmentUpdate.segmentName)
    }

    func testProcessMyLargeSegmentUpdateUnbounded() throws {
        let incoming = notificationParser.parseIncoming(jsonString: myLargeSegmentsUpdateNotificationUnboundedMessage);
        let mySegmentUpdate = try notificationParser.parseMyLargeSegmentUpdate(jsonString: incoming!.jsonData!);

        XCTAssertEqual(NotificationType.myLargeSegmentsUpdate, incoming?.type);
        XCTAssertEqual(.unboundedFetchRequest, mySegmentUpdate.updateStrategy);
        XCTAssertEqual(1702507130121, mySegmentUpdate.changeNumber)
        XCTAssertNil(mySegmentUpdate.data)
        XCTAssertNil(mySegmentUpdate.largeSegments)
        XCTAssertNil(mySegmentUpdate.hash)
        XCTAssertNil(mySegmentUpdate.seed)
        XCTAssertEqual(mySegmentUpdate.timeMillis, 100)

    }

    func testProcessMyLargeSegmentUpdateRemoval() throws {
        let incoming = notificationParser.parseIncoming(jsonString: myLargeSegmentsUpdateNotificationSegmentRemovalMessage);
        let mySegmentUpdate = try notificationParser.parseMyLargeSegmentUpdate(jsonString: incoming!.jsonData!);

        XCTAssertEqual(NotificationType.myLargeSegmentsUpdate, incoming?.type);
        XCTAssertEqual(.segmentRemoval, mySegmentUpdate.updateStrategy);
        XCTAssertEqual(1702507130121, mySegmentUpdate.changeNumber)
        XCTAssertEqual(["android_test", "ios_test"], mySegmentUpdate.largeSegments?.sorted())
        XCTAssertNil(mySegmentUpdate.data)
        XCTAssertNil(mySegmentUpdate.hash)
        XCTAssertNil(mySegmentUpdate.seed)
        XCTAssertNil(mySegmentUpdate.timeMillis)
    }

    func testProcessMyLargeSegmentUpdateAllFields() throws {
        let incoming = notificationParser.parseIncoming(jsonString: myLargeSegmentsUpdateNotificationAllFieldsMessage);
        let mySegmentUpdate = try notificationParser.parseMyLargeSegmentUpdate(jsonString: incoming!.jsonData!);

        XCTAssertEqual(NotificationType.myLargeSegmentsUpdate, incoming?.type);
        XCTAssertEqual(.unboundedFetchRequest, mySegmentUpdate.updateStrategy);
        XCTAssertEqual(1702507130121, mySegmentUpdate.changeNumber)
        XCTAssertEqual(["test"], mySegmentUpdate.largeSegments)
        XCTAssertEqual("eJwEwLsRwzAMA9BdWKsg+IFBraJTkRXS5rK7388+tg+KdC8+jq4eBBQLFcUnO8FAAC36gndOSEyFqJFP32Vf2+f+3wAAAP//hUQQ9A==", mySegmentUpdate.data)
        XCTAssertEqual(100, mySegmentUpdate.hash)
        XCTAssertEqual(200, mySegmentUpdate.seed)
        XCTAssertEqual(300, mySegmentUpdate.timeMillis)
    }

    func testProcessOccupancy() throws {
        let incoming = notificationParser.parseIncoming(jsonString: occupancyNotificationMessage);

        let notification = try notificationParser.parseOccupancy(jsonString: incoming!.jsonData!,
                                                                 timestamp: 5, channel: "control_pri");

        XCTAssertEqual(NotificationType.occupancy, notification.type);
        XCTAssertEqual(1, notification.metrics.publishers);
        XCTAssertEqual(5, notification.timestamp);
    }

    func testProcessControl() throws {
        let incoming = notificationParser.parseIncoming(jsonString: controlNotificationMessage);
        let notification = try notificationParser.parseControl(jsonString: incoming!.jsonData!);

        XCTAssertEqual(NotificationType.control, notification.type);
        XCTAssertEqual(ControlNotification.ControlType.streamingResumed, notification.controlType);
    }


    func testProcessError() {
        let incoming = notificationParser.parseIncoming(jsonString: errorNotificationMessage);

        XCTAssertEqual(NotificationType.sseError, incoming?.type);
    }

    func testExtractUserKeyHashFromChannel() {
        let expectedResult = "MTcwNTI2MTM0Mg=="

        let result = notificationParser.extractUserKeyHashFromChannel(channel: Self.kMySegmentsChannel)

        XCTAssertEqual(expectedResult, result)
    }

    override func tearDown() {
    }
}
