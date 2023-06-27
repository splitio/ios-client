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

    static let kUpdateSplitsNotificationZlib = """
{\"type\":\"SPLIT_UPDATE\",\"changeNumber\":1684265694505,\"pcn\":0,\"c\":2,\"d\":\"eJzMk99u2kwQxV8lOtdryQZj8N6hD5QPlThSTVNVEUKDPYZt1jZar1OlyO9emf8lVFWv2ss5zJyd82O8hTWUZSqZvW04opwhUVdsIKBSSKR+10vS1HWW7pIdz2NyBjRwHS8IXEopTLgbQqDYT+ZUm3LxlV4J4mg81LpMyKqygPRc94YeM6eQTtjphp4fegLVXvD6Qdjt9wPXF6gs2bqCxPC/2eRpDIEXpXXblpGuWCDljGptZ4bJ5lxYSJRZBoFkTcWKozpfsoH0goHfCXpB6PfcngDpVQnZEUjKIlOr2uwWqiC3zU5L1aF+3p7LFhUkPv8/mY2nk3gGgZxssmZzb8p6A9n25ktVtA9iGI3ODXunQ3HDp+AVWT6F+rZWlrWq7MN+YkSWWvuTDvkMSnNV7J6oTdl6qKTEvGnmjcCGjL2IYC/ovPYgUKnvvPtbmrmApiVryLM7p2jE++AfH6fTx09/HvuF32LWnNjStM0Xh3c8ukZcsZlEi3h8/zCObsBpJ0acqYLTmFdtqitK1V6NzrfpdPBbLmVx4uK26e27izpDu/r5yf/16AXun2Cr4u6w591xw7+LfDidLj6Mv8TXwP8xbofv/c7UmtHMmx8BAAD//0fclvU=\"}
"""

// decoded + decompressed
//{"trafficTypeName":"user","id":"d431cdd0-b0be-11ea-8a80-1660ada9ce39","name":"mauro_java","trafficAllocation":100,"trafficAllocationSeed":-92391491,"seed":-1769377604,"status":"ACTIVE","killed":false,"defaultTreatment":"off","changeNumber":1684265694505,"algo":2,"configurations":{},"conditions":[{"conditionType":"WHITELIST","matcherGroup":{"combiner":"AND","matchers":[{"matcherType":"WHITELIST","negate":false,"whitelistMatcherData":{"whitelist":["admin","mauro","nico"]}}]},"partitions":[{"treatment":"v5","size":100}],"label":"whitelisted"},{"conditionType":"ROLLOUT","matcherGroup":{"combiner":"AND","matchers":[{"keySelector":{"trafficType":"user"},"matcherType":"IN_SEGMENT","negate":false,"userDefinedSegmentMatcherData":{"segmentName":"maur-2"}}]},"partitions":[{"treatment":"on","size":0},{"treatment":"off","size":100},{"treatment":"V4","size":0},{"treatment":"v5","size":0}],"label":"in segment maur-2"},{"conditionType":"ROLLOUT","matcherGroup":{"combiner":"AND","matchers":[{"keySelector":{"trafficType":"user"},"matcherType":"ALL_KEYS","negate":false}]},"partitions":[{"treatment":"on","size":0},{"treatment":"off","size":100},{"treatment":"V4","size":0},{"treatment":"v5","size":0}],"label":"default rule"}]}


    static let kUpdateSplistNotificationGzip = """
{\"type\":\"SPLIT_UPDATE\",\"changeNumber\":1684265694505,\"pcn\":0,\"c\":1,\"d\":\"H4sIAAAAAAAA/8yT327aTBDFXyU612vJxoTgvUMfKB8qcaSapqoihAZ7DNusvWi9TpUiv3tl/pdQVb1qL+cwc3bOj/EGzlKeq3T6tuaYCoZEXbGFgMogkXXDIM0y31v4C/aCgMnrU9/3gl7Pp4yilMMIAuVusqDamvlXeiWIg/FAa5OSU6aEDHz/ip4wZ5Be1AmjoBsFAtVOCO56UXh31/O7ApUjV1eQGPw3HT+NIPCitG7bctIVC2ScU63d1DK5gksHCZPnEEhXVC45rosFW8ig1++GYej3g85tJEB6aSA7Aqkpc7Ws7XahCnLTbLVM7evnzalsUUHi8//j6WgyTqYQKMilK7b31tRryLa3WKiyfRCDeHhq2Dntiys+JS/J8THUt5VyrFXlHnYTQ3LU2h91yGdQVqhy+0RtTeuhUoNZ08wagTVZdxbBndF5vYVApb7z9m9pZgKaFqwhT+6coRHvg398nEweP/157Bd+S1hz6oxtm88O73B0jbhgM47nyej+YRRfgdNODDlXJWcJL9tUF5SqnRqfbtPr4LdcTHnk4rfp3buLOkG7+Pmp++vRM9w/wVblzX7Pm8OGfxf5YDKZfxh9SS6B/2Pc9t/7ja01o5k1PwIAAP//uTipVskEAAA=\"}
"""

//// decoded + decompressed
//{"trafficTypeName":"user","id":"d431cdd0-b0be-11ea-8a80-1660ada9ce39","name":"mauro_java","trafficAllocation":100,"trafficAllocationSeed":-92391491,"seed":-1769377604,"status":"ACTIVE","killed":false,"defaultTreatment":"off","changeNumber":1684333081259,"algo":2,"configurations":{},"conditions":[{"conditionType":"WHITELIST","matcherGroup":{"combiner":"AND","matchers":[{"matcherType":"WHITELIST","negate":false,"whitelistMatcherData":{"whitelist":["admin","mauro","nico"]}}]},"partitions":[{"treatment":"v5","size":100}],"label":"whitelisted"},{"conditionType":"ROLLOUT","matcherGroup":{"combiner":"AND","matchers":[{"keySelector":{"trafficType":"user"},"matcherType":"IN_SEGMENT","negate":false,"userDefinedSegmentMatcherData":{"segmentName":"maur-2"}}]},"partitions":[{"treatment":"on","size":0},{"treatment":"off","size":100},{"treatment":"V4","size":0},{"treatment":"v5","size":0}],"label":"in segment maur-2"},{"conditionType":"ROLLOUT","matcherGroup":{"combiner":"AND","matchers":[{"keySelector":{"trafficType":"user"},"matcherType":"ALL_KEYS","negate":false}]},"partitions":[{"treatment":"on","size":0},{"treatment":"off","size":100},{"treatment":"V4","size":0},{"treatment":"v5","size":0}],"label":"default rule"}]}"



// MARK: Functions

    static func encodedKeyListPayloadGzip() -> String {
        do {
            let notification = try Json.decodeFrom(json: kKeyListNotificationGzip, to: MySegmentsUpdateV2Notification.self)
            return notification.data ?? ""
        } catch {
            print("encodedKeyListPayloadGzip \(error)")
        }
        return ""
    }

    static func encodedBoundedPayloadGzip() -> String {
        do {
            let notification = try Json.decodeFrom(json: kBoundedNotificationGzip, to: MySegmentsUpdateV2Notification.self)
            return notification.data ?? ""
        } catch {
            print("encodedBoundedPayloadGzip \(error)")
        }
        return ""
    }

    static func encodedBoundedPayloadZlib() -> String {
        do {
            let notification = try Json.decodeFrom(json: kBoundedNotificationZlib, to: MySegmentsUpdateV2Notification.self)
            return notification.data ?? ""
        } catch {
            print("encodedBoundedPayloadZlib \(error)")
        }
        return ""
    }

    static func updateSplitsNotificationZlib() -> SplitsUpdateNotification {
        return try! Json.decodeFrom(json: kUpdateSplitsNotificationZlib, to: SplitsUpdateNotification.self)
    }

    static func updateSplitsNotificationGzip() -> SplitsUpdateNotification {
        return try! Json.decodeFrom(json: kUpdateSplistNotificationGzip, to: SplitsUpdateNotification.self)
    }

}
