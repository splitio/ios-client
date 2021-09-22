//
//  TestingData.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 14-Sep-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split

struct TestingData {
    ///
    /// Keylist payload Gzip
    /// {"a":[1573573083296714675,8482869187405483569],"r":[8031872927333060586,6829471020522910836]}
    /// = a: [key1, key2] , r: [key3, key4]
    ///
    static let kKeyListNotificationGzip = """
    {
        \"type\": \"MY_SEGMENTS_UPDATE_V2\",
        \"u\": 2,
        \"c\": 1,
        \"d\": \"H4sIAAAAAAAA/wTAsRHDUAgD0F2ofwEIkPAqPhdZIW0uu/v97GPXHU004ULuMGrYR6XUbIjlXULPPse+dt1yhJibBODjrTmj3GJ4emduuDDP/w0AAP//18WLsl0AAAA=\"
    }
    """

    /**
     Key for bounded payload Gzip
     603516ce-1243-400b-b919-0dce5d8aecfd
     88f8b33b-f858-4aea-bea2-a5f066bab3ce
     375903c8-6f62-4272-88f1-f8bcd304c7ae
     18c936ad-0cd2-490d-8663-03eaa23a5ef1
     bfd4a824-0cde-4f11-9700-2b4c5ad6f719
     4588c4f6-3d18-452a-bc4a-47d7abfd23df
     42bcfe02-d268-472f-8ed5-e6341c33b4f7
     2a7cae0e-85a2-443e-9d7c-7157b7c5960a
     4b0b0467-3fe1-43d1-a3d5-937c0a5473b1
     09025e90-d396-433a-9292-acef23cf0ad1
     [11288179738259047283 10949366897533296036 9142072388263950989 51944159202969851
     8492584437244343049 11382796718859679607 11383137936375052427 17699699514337596928 17001541343685934583 8355202062888946034]
     */
    static let kBoundedNotificationGzip = """
    {
                \"type\": \"MY_SEGMENTS_UPDATE_V2\",
                \"u\": 1,
                \"c\": 1,
                \"d\": \"H4sIAAAAAAAA/2IYBfgAx0A7YBTgB4wD7YABAAID7QC6g5EYy8MEMA20A+gMFAbaAYMZDPXqlGWgHTAKRsEoGAWjgCzQQFjJkKqiiPAPAQAIAAD//5L7VQwAEAAA\"
                }
    """

    static let kBoundedNotificationZlib = """
    {
            \"type\": \"MY_SEGMENTS_UPDATE_V2\",
            \"u\": 1,
            \"c\": 2,
            \"d\": \"eJxiGAX4AMdAO2AU4AeMA+2AAQACA+0AuoORGMvDBDANtAPoDBQG2gGDGQz16pRloB0wCkbBKBgFo4As0EBYyZCqoojwDwEACAAA//+W/QFR\"
            }
    """

    static let kUnboundedNotification = """
    {
                \\\"type\\\": \\\"MY_SEGMENTS_UPDATE_V2\\\",
                \\\"u\\\": 0,
                \\\"c\\\": 0,
                \\\"d\\\": \\\"\\\",
                \\\"segmentName\\\": \\\"pepe\\\",
                \\\"changeNumber\\\": 28
                }
    """

    static let kSegmentRemovalNotification = """
    {
                \\\"type\\\": \\\"MY_SEGMENTS_UPDATE_V2\\\",
                \\\"u\\\": 3,
                \\\"c\\\": 0,
                \\\"d\\\": \\\"\\\",
                \\\"segmentName\\\": \\\"segment1\\\",
                \\\"changeNumber\\\": 28
                }
    """

    static let kEscapedKeyListNotificationGzip = """
    {
                \\\"type\\\": \\\"MY_SEGMENTS_UPDATE_V2\\\",
                \\\"segmentName\\\": \\\"new_segment_added\\\",
                \\\"u\\\": 2,
                \\\"c\\\": 1,
                \\\"d\\\": \\\"H4sIAAAAAAAA/wTAsRHDUAgD0F2ofwEIkPAqPhdZIW0uu/v97GPXHU004ULuMGrYR6XUbIjlXULPPse+dt1yhJibBODjrTmj3GJ4emduuDDP/w0AAP//18WLsl0AAAA=\\\"
                }
    """

    static let kEscapedBoundedNotificationGzip  = """
    {
                \\\"type\\\": \\\"MY_SEGMENTS_UPDATE_V2\\\",
                \\\"u\\\": 1,
                \\\"c\\\": 1,
                \\\"d\\\": \\\"H4sIAAAAAAAA/2IYBfgAx0A7YBTgB4wD7YABAAID7QC6g5EYy8MEMA20A+gMFAbaAYMZDPXqlGWgHTAKRsEoGAWjgCzQQFjJkKqiiPAPAQAIAAD//5L7VQwAEAAA\\\"
                }
    """

    static let kEscapedBoundedNotificationZlib = """
    {
                \\\"type\\\": \\\"MY_SEGMENTS_UPDATE_V2\\\",
                \\\"u\\\": 1,
                \\\"c\\\": 2,
                \\\"d\\\": \\\"eJxiGAX4AMdAO2AU4AeMA+2AAQACA+0AuoORGMvDBDANtAPoDBQG2gGDGQz16pRloB0wCkbBKBgFo4As0EBYyZCqoojwDwEACAAA//+W/QFR\\\"
                }
    """

    static let kEscapedBoundedNotificationMalformed = """
    {
                \\\"type\\\": \\\"MY_SEGMENTS_UPDATE_V2\\\",
                \\\"u\\\": 1,
                \\\"c\\\": 1,
                \\\"d\\\": \\\"aaaH4sIAAAAAAAAg5EYy8MEMA20A+//5L7VQwAEAAA\\\"
                }
    """

    static func encodedKeyListPayloadGzip() -> String {
        do {
            let notification = try Json.encodeFrom(json: kKeyListNotificationGzip, to: MySegmentsUpdateV2Notification.self)
            return notification.data ?? ""
        } catch {
            print("encodedKeyListPayloadGzip \(error)")
        }
        return ""
    }

    static func encodedBoundedPayloadGzip() -> String {
        do {
            let notification = try Json.encodeFrom(json: kBoundedNotificationGzip, to: MySegmentsUpdateV2Notification.self)
            return notification.data ?? ""
        } catch {
            print("encodedBoundedPayloadGzip \(error)")
        }
        return ""
    }

    static func encodedBoundedPayloadZlib() -> String {
        do {
            let notification = try Json.encodeFrom(json: kBoundedNotificationZlib, to: MySegmentsUpdateV2Notification.self)
            return notification.data ?? ""
        } catch {
            print("encodedBoundedPayloadZlib \(error)")
        }
        return ""
    }
}
