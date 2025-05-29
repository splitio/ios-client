//
//  TestingData.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 14-Sep-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split

enum TestingData {
    static let keepalive = ":keepalive"

    ///
    /// Keylist payload Gzip
    /// {"a":[1573573083296714675,8482869187405483569],"r":[8031872927333060586,6829471020522910836]}
    /// = a: [key1, key2] , r: [key3, key4]
    ///
    static let kKeyListNotificationGzip = """
    {
        \"type\": \"MEMBERSHIPS_MS_UPDATE\",
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
                \"type\": \"MEMBERSHIPS_MS_UPDATE\",
                \"u\": 1,
                \"c\": 1,
                \"d\": \"H4sIAAAAAAAA/2IYBfgAx0A7YBTgB4wD7YABAAID7QC6g5EYy8MEMA20A+gMFAbaAYMZDPXqlGWgHTAKRsEoGAWjgCzQQFjJkKqiiPAPAQAIAAD//5L7VQwAEAAA\"
                }
    """

    static let kBoundedNotificationZlib = """
    {
            \"type\": \"MEMBERSHIPS_MS_UPDATE\",
            \"u\": 1,
            \"c\": 2,
            \"d\": \"eJxiGAX4AMdAO2AU4AeMA+2AAQACA+0AuoORGMvDBDANtAPoDBQG2gGDGQz16pRloB0wCkbBKBgFo4As0EBYyZCqoojwDwEACAAA//+W/QFR\"
            }
    """

    static func delayedUnboundedNotification(type: NotificationType, cn: Int = -1, delay: Int = 500) -> String {
        let notificationType = str(type)
        let kUnboundedNotification = """
        {
                    \\\"type\\\": \\\"\(notificationType)\\\",
                    \\\"u\\\": 0,
                    \\\"c\\\": 0,
                    \\\"h\\\": 1,
                    \\\"s\\\": 1,
                    \\\"i\\\": \(delay),
                    \\\"d\\\": \\\"\\\",
                    \\\"n\\\": [\\\"pepe\\\"],
                    \\\"cn\\\": \(cn)
                    }
        """
        return kUnboundedNotification
    }

    static func unboundedNotification(type: NotificationType, cn: Int = -1) -> String {
        let notificationType = str(type)
        let kUnboundedNotification = """
        {
                    \\\"type\\\": \\\"\(notificationType)\\\",
                    \\\"u\\\": 0,
                    \\\"c\\\": 0,
                    \\\"d\\\": \\\"\\\",
                    \\\"n\\\": [\\\"pepe\\\"],
                    \\\"cn\\\": \(cn)
                    }
        """
        return kUnboundedNotification
    }

    static func segmentRemovalNotification(type: NotificationType, cn: Int = -1) -> String {
        let notificationType = str(type)
        let kSegmentRemovalNotification = """
        {
                    \\\"type\\\": \\\"\(notificationType)\\\",
                    \\\"u\\\": 3,
                    \\\"c\\\": 0,
                    \\\"d\\\": \\\"\\\",
                    \\\"n\\\": [\\\"segment1\\\"],
                    \\\"cn\\\": \(cn)
                    }
        """
        return kSegmentRemovalNotification
    }

    static func escapedKeyListNotificationGzip(type: NotificationType, cn: Int = -1) -> String {
        let notificationType = str(type)
        let kEscapedKeyListNotificationGzip = """
        {
                    \\\"type\\\": \\\"\(notificationType)\\\",
                    \\\"n\\\": [\\\"new_segment_added\\\"],
                    \\\"u\\\": 2,
                    \\\"c\\\": 1,
                    \\\"cn\\\": \(cn),
                    \\\"d\\\": \\\"H4sIAAAAAAAA/wTAsRHDUAgD0F2ofwEIkPAqPhdZIW0uu/v97GPXHU004ULuMGrYR6XUbIjlXULPPse+dt1yhJibBODjrTmj3GJ4emduuDDP/w0AAP//18WLsl0AAAA=\\\"
                    }
        """
        return kEscapedKeyListNotificationGzip
    }

    static func escapedBoundedNotificationGzip(type: NotificationType, cn: Int = -1) -> String {
        let notificationType = str(type)
        let kEscapedBoundedNotificationGzip = """
        {
                    \\\"type\\\": \\\"\(notificationType)\\\",
                    \\\"u\\\": 1,
                    \\\"c\\\": 1,
                    \\\"cn\\\": \(cn),
                    \\\"d\\\": \\\"H4sIAAAAAAAA/2IYBfgAx0A7YBTgB4wD7YABAAID7QC6g5EYy8MEMA20A+gMFAbaAYMZDPXqlGWgHTAKRsEoGAWjgCzQQFjJkKqiiPAPAQAIAAD//5L7VQwAEAAA\\\"
                    }
        """
        return kEscapedBoundedNotificationGzip
    }

    static func escapedBoundedNotificationZlib(type: NotificationType, cn: Int = -1) -> String {
        let notificationType = str(type)
        let kEscapedBoundedNotificationZlib = """
        {
                    \\\"type\\\": \\\"\(notificationType)\\\",
                    \\\"u\\\": 1,
                    \\\"c\\\": 2,
                    \\\"cn\\\": \(cn),
                    \\\"d\\\": \\\"eJxiGAX4AMdAO2AU4AeMA+2AAQACA+0AuoORGMvDBDANtAPoDBQG2gGDGQz16pRloB0wCkbBKBgFo4As0EBYyZCqoojwDwEACAAA//+W/QFR\\\"
                    }
        """
        return kEscapedBoundedNotificationZlib
    }

    static func escapedBoundedNotificationMalformed(type: NotificationType, cn: Int = -1) -> String {
        let notificationType = str(type)

        let kEscapedBoundedNotificationMalformed = """
        {
                    \\\"type\\\": \\\"\(notificationType)\\\",
                    \\\"u\\\": 1,
                    \\\"c\\\": 1,
                    \\\"cn\\\": \(cn),
                    \\\"d\\\": \\\"aaaH4sIAAAAAAAAg5EYy8MEMA20A+//5L7VQwAEAAA\\\"
                    }
        """
        return kEscapedBoundedNotificationMalformed
    }

    static func str(_ type: NotificationType) -> String {
        return type == .mySegmentsUpdate ? "MEMBERSHIPS_MS_UPDATE" : "MEMBERSHIPS_LS_UPDATE"
    }

    static let kUpdateSplitsNotificationZlib = """
    {\"type\":\"SPLIT_UPDATE\",\"changeNumber\":1684265694505,\"pcn\":0,\"c\":2,\"d\":\"eJzMk99u2kwQxV8lOtdryQZj8N6hD5QPlThSTVNVEUKDPYZt1jZar1OlyO9emf8lVFWv2ss5zJyd82O8hTWUZSqZvW04opwhUVdsIKBSSKR+10vS1HWW7pIdz2NyBjRwHS8IXEopTLgbQqDYT+ZUm3LxlV4J4mg81LpMyKqygPRc94YeM6eQTtjphp4fegLVXvD6Qdjt9wPXF6gs2bqCxPC/2eRpDIEXpXXblpGuWCDljGptZ4bJ5lxYSJRZBoFkTcWKozpfsoH0goHfCXpB6PfcngDpVQnZEUjKIlOr2uwWqiC3zU5L1aF+3p7LFhUkPv8/mY2nk3gGgZxssmZzb8p6A9n25ktVtA9iGI3ODXunQ3HDp+AVWT6F+rZWlrWq7MN+YkSWWvuTDvkMSnNV7J6oTdl6qKTEvGnmjcCGjL2IYC/ovPYgUKnvvPtbmrmApiVryLM7p2jE++AfH6fTx09/HvuF32LWnNjStM0Xh3c8ukZcsZlEi3h8/zCObsBpJ0acqYLTmFdtqitK1V6NzrfpdPBbLmVx4uK26e27izpDu/r5yf/16AXun2Cr4u6w591xw7+LfDidLj6Mv8TXwP8xbofv/c7UmtHMmx8BAAD//0fclvU=\"}
    """

    static let kEscapedUpdateSplitsNotificationZlib = """
    {\\\"type\\\":\\\"SPLIT_UPDATE\\\",\\\"changeNumber\\\":1684265694505,\\\"pcn\\\":100,\\\"c\\\":2,\\\"d\\\":\\\"eJzMk99u2kwQxV8lOtdryQZj8N6hD5QPlThSTVNVEUKDPYZt1jZar1OlyO9emf8lVFWv2ss5zJyd82O8hTWUZSqZvW04opwhUVdsIKBSSKR+10vS1HWW7pIdz2NyBjRwHS8IXEopTLgbQqDYT+ZUm3LxlV4J4mg81LpMyKqygPRc94YeM6eQTtjphp4fegLVXvD6Qdjt9wPXF6gs2bqCxPC/2eRpDIEXpXXblpGuWCDljGptZ4bJ5lxYSJRZBoFkTcWKozpfsoH0goHfCXpB6PfcngDpVQnZEUjKIlOr2uwWqiC3zU5L1aF+3p7LFhUkPv8/mY2nk3gGgZxssmZzb8p6A9n25ktVtA9iGI3ODXunQ3HDp+AVWT6F+rZWlrWq7MN+YkSWWvuTDvkMSnNV7J6oTdl6qKTEvGnmjcCGjL2IYC/ovPYgUKnvvPtbmrmApiVryLM7p2jE++AfH6fTx09/HvuF32LWnNjStM0Xh3c8ukZcsZlEi3h8/zCObsBpJ0acqYLTmFdtqitK1V6NzrfpdPBbLmVx4uK26e27izpDu/r5yf/16AXun2Cr4u6w591xw7+LfDidLj6Mv8TXwP8xbofv/c7UmtHMmx8BAAD//0fclvU=\\\"}
    """

    // decoded + decompressed
    // {"trafficTypeName":"user","id":"d431cdd0-b0be-11ea-8a80-1660ada9ce39","name":"mauro_java","trafficAllocation":100,"trafficAllocationSeed":-92391491,"seed":-1769377604,"status":"ACTIVE","killed":false,"defaultTreatment":"off","changeNumber":1684265694505,"algo":2,"configurations":{},"conditions":[{"conditionType":"WHITELIST","matcherGroup":{"combiner":"AND","matchers":[{"matcherType":"WHITELIST","negate":false,"whitelistMatcherData":{"whitelist":["admin","mauro","nico"]}}]},"partitions":[{"treatment":"v5","size":100}],"label":"whitelisted"},{"conditionType":"ROLLOUT","matcherGroup":{"combiner":"AND","matchers":[{"keySelector":{"trafficType":"user"},"matcherType":"IN_SEGMENT","negate":false,"userDefinedSegmentMatcherData":{"segmentName":"maur-2"}}]},"partitions":[{"treatment":"on","size":0},{"treatment":"off","size":100},{"treatment":"V4","size":0},{"treatment":"v5","size":0}],"label":"in segment maur-2"},{"conditionType":"ROLLOUT","matcherGroup":{"combiner":"AND","matchers":[{"keySelector":{"trafficType":"user"},"matcherType":"ALL_KEYS","negate":false}]},"partitions":[{"treatment":"on","size":0},{"treatment":"off","size":100},{"treatment":"V4","size":0},{"treatment":"v5","size":0}],"label":"default rule"}]}

    static let kUpdateSplitsNotificationGzip = """
    {\"type\":\"SPLIT_UPDATE\",\"changeNumber\":1684265694505,\"pcn\":100,\"c\":1,\"d\":\"H4sIAAAAAAAA/8yT327aTBDFXyU612vJxoTgvUMfKB8qcaSapqoihAZ7DNusvWi9TpUiv3tl/pdQVb1qL+cwc3bOj/EGzlKeq3T6tuaYCoZEXbGFgMogkXXDIM0y31v4C/aCgMnrU9/3gl7Pp4yilMMIAuVusqDamvlXeiWIg/FAa5OSU6aEDHz/ip4wZ5Be1AmjoBsFAtVOCO56UXh31/O7ApUjV1eQGPw3HT+NIPCitG7bctIVC2ScU63d1DK5gksHCZPnEEhXVC45rosFW8ig1++GYej3g85tJEB6aSA7Aqkpc7Ws7XahCnLTbLVM7evnzalsUUHi8//j6WgyTqYQKMilK7b31tRryLa3WKiyfRCDeHhq2Dntiys+JS/J8THUt5VyrFXlHnYTQ3LU2h91yGdQVqhy+0RtTeuhUoNZ08wagTVZdxbBndF5vYVApb7z9m9pZgKaFqwhT+6coRHvg398nEweP/157Bd+S1hz6oxtm88O73B0jbhgM47nyej+YRRfgdNODDlXJWcJL9tUF5SqnRqfbtPr4LdcTHnk4rfp3buLOkG7+Pmp++vRM9w/wVblzX7Pm8OGfxf5YDKZfxh9SS6B/2Pc9t/7ja01o5k1PwIAAP//uTipVskEAAA=\"}
    """

    static let kEscapedUpdateSplitsNotificationGzip = """
    {\\\"type\\\":\\\"SPLIT_UPDATE\\\",\\\"changeNumber\\\":1684265694505,\\\"pcn\\\":100,\\\"c\\\":1,\\\"d\\\":\\\"H4sIAAAAAAAA/8yT327aTBDFXyU612vJxoTgvUMfKB8qcaSapqoihAZ7DNusvWi9TpUiv3tl/pdQVb1qL+cwc3bOj/EGzlKeq3T6tuaYCoZEXbGFgMogkXXDIM0y31v4C/aCgMnrU9/3gl7Pp4yilMMIAuVusqDamvlXeiWIg/FAa5OSU6aEDHz/ip4wZ5Be1AmjoBsFAtVOCO56UXh31/O7ApUjV1eQGPw3HT+NIPCitG7bctIVC2ScU63d1DK5gksHCZPnEEhXVC45rosFW8ig1++GYej3g85tJEB6aSA7Aqkpc7Ws7XahCnLTbLVM7evnzalsUUHi8//j6WgyTqYQKMilK7b31tRryLa3WKiyfRCDeHhq2Dntiys+JS/J8THUt5VyrFXlHnYTQ3LU2h91yGdQVqhy+0RtTeuhUoNZ08wagTVZdxbBndF5vYVApb7z9m9pZgKaFqwhT+6coRHvg398nEweP/157Bd+S1hz6oxtm88O73B0jbhgM47nyej+YRRfgdNODDlXJWcJL9tUF5SqnRqfbtPr4LdcTHnk4rfp3buLOkG7+Pmp++vRM9w/wVblzX7Pm8OGfxf5YDKZfxh9SS6B/2Pc9t/7ja01o5k1PwIAAP//uTipVskEAAA=\\\"}
    """

    //// decoded + decompressed
    // {"trafficTypeName":"user","id":"d431cdd0-b0be-11ea-8a80-1660ada9ce39","name":"mauro_java","trafficAllocation":100,"trafficAllocationSeed":-92391491,"seed":-1769377604,"status":"ACTIVE","killed":false,"defaultTreatment":"off","changeNumber":1684333081259,"algo":2,"configurations":{},"conditions":[{"conditionType":"WHITELIST","matcherGroup":{"combiner":"AND","matchers":[{"matcherType":"WHITELIST","negate":false,"whitelistMatcherData":{"whitelist":["admin","mauro","nico"]}}]},"partitions":[{"treatment":"v5","size":100}],"label":"whitelisted"},{"conditionType":"ROLLOUT","matcherGroup":{"combiner":"AND","matchers":[{"keySelector":{"trafficType":"user"},"matcherType":"IN_SEGMENT","negate":false,"userDefinedSegmentMatcherData":{"segmentName":"maur-2"}}]},"partitions":[{"treatment":"on","size":0},{"treatment":"off","size":100},{"treatment":"V4","size":0},{"treatment":"v5","size":0}],"label":"in segment maur-2"},{"conditionType":"ROLLOUT","matcherGroup":{"combiner":"AND","matchers":[{"keySelector":{"trafficType":"user"},"matcherType":"ALL_KEYS","negate":false}]},"partitions":[{"treatment":"on","size":0},{"treatment":"off","size":100},{"treatment":"V4","size":0},{"treatment":"v5","size":0}],"label":"default rule"}]}"

    // base64 + zlib + archived
    static let kArchivedFeatureFlagZlib = """
    {\\\"type\\\":\\\"SPLIT_UPDATE\\\",\\\"changeNumber\\\":1686165617166,\\\"pcn\\\":500,\\\"c\\\":2,\\\"d\\\":\\\"eJxsUdFu4jAQ/JVqnx3JDjTh/JZCrj2JBh0EqtOBIuNswKqTIMeuxKH8+ykhiKrqiyXvzM7O7lzAGlEUSqbnEyaiRODgGjRAQOXAIQ/puPB96tHHIPQYQ/QmFNErxEgG44DKnI2AQHXtTOI0my6WcXZAmxoUtsTKvil7nNZVoQ5RYdFERh7VBwK5TY60rqWwqq6AM0q/qa8Qc+As/EHZ5HHMCDR9wQ/9kIajcEygscK6BjhEy+nLr008AwLvSuuOVgjdIIEcC+H03RZw2Hg/n88JEJBHUR0wceUeDXAWTAIWPAYsZEFAQOhDDdwnIPslnOk9NcAvNwEOly3IWtdmC3wLe+1wCy0Q2Hh/zNvTV9xg3sFtr5irQe3v5f7twgAOy8V8vlinQKAUVh7RPJvanbrBsi73qurMQpTM7oSrzjueV6hR2tp05E8J39MV1hq1d7YrWWxsZ2cQGYjzeLXK0pcoyRbLLP69juZZuuiyxoPo2oa7ukqYc+JKNEq+XgVmwopucC6sGMSS9etTvAQCH0I7BO7Ttt21BE7C2E8XsN+l06h/CJy25CveH/eGM0rbHQEt9qiHnR62jtKR7N/8wafQ7tr/AQAA//8S4fPB\\\"}
    """
    //    // decoded
    //    {\"trafficTypeName\":\"user\",\"id\":\"d704f220-0567-11ee-80ee-fa3c6460cd13\",\"name\":\"NET_CORE_getTreatmentWithConfigAfterArchive\",\"trafficAllocation\":100,\"trafficAllocationSeed\":179018541,\"seed\":272707374,\"status\":\"ARCHIVED\",\"killed\":false,\"defaultTreatment\":\"V-FGyN\",\"changeNumber\":1686165617166,\"algo\":2,\"configurations\":{\"V-FGyN\":\"{\\\"color\\\":\\\"blue\\\"}\",\"V-YrWB\":\"{\\\"color\\\":\\\"red\\\"}\"},\"conditions\":[{\"conditionType\":\"ROLLOUT\",\"matcherGroup\":{\"combiner\":\"AND\",\"matchers\":[{\"keySelector\":{\"trafficType\":\"user\",\"attribute\":\"test\"},\"matcherType\":\"LESS_THAN_OR_EQUAL_TO\",\"negate\":false,\"unaryNumericMatcherData\":{\"dataType\":\"NUMBER\",\"value\":20}}]},\"partitions\":[{\"treatment\":\"V-FGyN\",\"size\":0},{\"treatment\":\"V-YrWB\",\"size\":100}],\"label\":\"test \\u003c\\u003d 20\"}]}"

    static let kFlagSetsNotification2 = """
        {\\\"type\\\":\\\"SPLIT_UPDATE\\\",\\\"changeNumber\\\":2,\\\"pcn\\\":1,\\\"c\\\":0,\\\"d\\\":\\\"eyJ0cmFmZmljVHlwZU5hbWUiOiJjbGllbnQiLCJuYW1lIjoid29ya20iLCJ0cmFmZmljQWxsb2NhdGlvbiI6MTAwLCJ0cmFmZmljQWxsb2NhdGlvblNlZWQiOjE0NzM5MjIyNCwic2VlZCI6NTI0NDE3MTA1LCJzdGF0dXMiOiJBQ1RJVkUiLCJraWxsZWQiOmZhbHNlLCJkZWZhdWx0VHJlYXRtZW50Ijoib24iLCJjaGFuZ2VOdW1iZXIiOjIsImFsZ28iOjIsImNvbmZpZ3VyYXRpb25zIjp7fSwic2V0cyI6WyJzZXRfMSIsInNldF8yIl0sImNvbmRpdGlvbnMiOlt7ImNvbmRpdGlvblR5cGUiOiJST0xMT1VUIiwibWF0Y2hlckdyb3VwIjp7ImNvbWJpbmVyIjoiQU5EIiwibWF0Y2hlcnMiOlt7ImtleVNlbGVjdG9yIjp7InRyYWZmaWNUeXBlIjoiY2xpZW50IiwiYXR0cmlidXRlIjpudWxsfSwibWF0Y2hlclR5cGUiOiJJTl9TRUdNRU5UIiwibmVnYXRlIjpmYWxzZSwidXNlckRlZmluZWRTZWdtZW50TWF0Y2hlckRhdGEiOnsic2VnbWVudE5hbWUiOiJuZXdfc2VnbWVudCJ9LCJ3aGl0ZWxpc3RNYXRjaGVyRGF0YSI6bnVsbCwidW5hcnlOdW1lcmljTWF0Y2hlckRhdGEiOm51bGwsImJldHdlZW5NYXRjaGVyRGF0YSI6bnVsbCwiYm9vbGVhbk1hdGNoZXJEYXRhIjpudWxsLCJkZXBlbmRlbmN5TWF0Y2hlckRhdGEiOm51bGwsInN0cmluZ01hdGNoZXJEYXRhIjpudWxsfV19LCJwYXJ0aXRpb25zIjpbeyJ0cmVhdG1lbnQiOiJvbiIsInNpemUiOjB9LHsidHJlYXRtZW50Ijoib2ZmIiwic2l6ZSI6MH0seyJ0cmVhdG1lbnQiOiJmcmVlIiwic2l6ZSI6MTAwfSx7InRyZWF0bWVudCI6ImNvbnRhIiwic2l6ZSI6MH1dLCJsYWJlbCI6ImluIHNlZ21lbnQgbmV3X3NlZ21lbnQifSx7ImNvbmRpdGlvblR5cGUiOiJST0xMT1VUIiwibWF0Y2hlckdyb3VwIjp7ImNvbWJpbmVyIjoiQU5EIiwibWF0Y2hlcnMiOlt7ImtleVNlbGVjdG9yIjp7InRyYWZmaWNUeXBlIjoiY2xpZW50IiwiYXR0cmlidXRlIjpudWxsfSwibWF0Y2hlclR5cGUiOiJBTExfS0VZUyIsIm5lZ2F0ZSI6ZmFsc2UsInVzZXJEZWZpbmVkU2VnbWVudE1hdGNoZXJEYXRhIjpudWxsLCJ3aGl0ZWxpc3RNYXRjaGVyRGF0YSI6bnVsbCwidW5hcnlOdW1lcmljTWF0Y2hlckRhdGEiOm51bGwsImJldHdlZW5NYXRjaGVyRGF0YSI6bnVsbCwiYm9vbGVhbk1hdGNoZXJEYXRhIjpudWxsLCJkZXBlbmRlbmN5TWF0Y2hlckRhdGEiOm51bGwsInN0cmluZ01hdGNoZXJEYXRhIjpudWxsfV19LCJwYXJ0aXRpb25zIjpbeyJ0cmVhdG1lbnQiOiJvbiIsInNpemUiOjEwMH0seyJ0cmVhdG1lbnQiOiJvZmYiLCJzaXplIjowfSx7InRyZWF0bWVudCI6ImZyZWUiLCJzaXplIjowfSx7InRyZWF0bWVudCI6ImNvbnRhIiwic2l6ZSI6MH1dLCJsYWJlbCI6ImRlZmF1bHQgcnVsZSJ9XX0\\\"}
    """

    static let kFlagSetsNotification3 = """
    {\\\"type\\\":\\\"SPLIT_UPDATE\\\",\\\"changeNumber\\\":3,\\\"pcn\\\":2,\\\"c\\\":0,\\\"d\\\":\\\"eyJ0cmFmZmljVHlwZU5hbWUiOiJjbGllbnQiLCJuYW1lIjoid29ya20iLCJ0cmFmZmljQWxsb2NhdGlvbiI6MTAwLCJ0cmFmZmljQWxsb2NhdGlvblNlZWQiOjE0NzM5MjIyNCwic2VlZCI6NTI0NDE3MTA1LCJzdGF0dXMiOiJBQ1RJVkUiLCJraWxsZWQiOmZhbHNlLCJkZWZhdWx0VHJlYXRtZW50Ijoib24iLCJjaGFuZ2VOdW1iZXIiOjMsImFsZ28iOjIsImNvbmZpZ3VyYXRpb25zIjp7fSwic2V0cyI6WyJzZXRfMSJdLCJjb25kaXRpb25zIjpbeyJjb25kaXRpb25UeXBlIjoiUk9MTE9VVCIsIm1hdGNoZXJHcm91cCI6eyJjb21iaW5lciI6IkFORCIsIm1hdGNoZXJzIjpbeyJrZXlTZWxlY3RvciI6eyJ0cmFmZmljVHlwZSI6ImNsaWVudCIsImF0dHJpYnV0ZSI6bnVsbH0sIm1hdGNoZXJUeXBlIjoiSU5fU0VHTUVOVCIsIm5lZ2F0ZSI6ZmFsc2UsInVzZXJEZWZpbmVkU2VnbWVudE1hdGNoZXJEYXRhIjp7InNlZ21lbnROYW1lIjoibmV3X3NlZ21lbnQifSwid2hpdGVsaXN0TWF0Y2hlckRhdGEiOm51bGwsInVuYXJ5TnVtZXJpY01hdGNoZXJEYXRhIjpudWxsLCJiZXR3ZWVuTWF0Y2hlckRhdGEiOm51bGwsImJvb2xlYW5NYXRjaGVyRGF0YSI6bnVsbCwiZGVwZW5kZW5jeU1hdGNoZXJEYXRhIjpudWxsLCJzdHJpbmdNYXRjaGVyRGF0YSI6bnVsbH1dfSwicGFydGl0aW9ucyI6W3sidHJlYXRtZW50Ijoib24iLCJzaXplIjowfSx7InRyZWF0bWVudCI6Im9mZiIsInNpemUiOjB9LHsidHJlYXRtZW50IjoiZnJlZSIsInNpemUiOjEwMH0seyJ0cmVhdG1lbnQiOiJjb250YSIsInNpemUiOjB9XSwibGFiZWwiOiJpbiBzZWdtZW50IG5ld19zZWdtZW50In0seyJjb25kaXRpb25UeXBlIjoiUk9MTE9VVCIsIm1hdGNoZXJHcm91cCI6eyJjb21iaW5lciI6IkFORCIsIm1hdGNoZXJzIjpbeyJrZXlTZWxlY3RvciI6eyJ0cmFmZmljVHlwZSI6ImNsaWVudCIsImF0dHJpYnV0ZSI6bnVsbH0sIm1hdGNoZXJUeXBlIjoiQUxMX0tFWVMiLCJuZWdhdGUiOmZhbHNlLCJ1c2VyRGVmaW5lZFNlZ21lbnRNYXRjaGVyRGF0YSI6bnVsbCwid2hpdGVsaXN0TWF0Y2hlckRhdGEiOm51bGwsInVuYXJ5TnVtZXJpY01hdGNoZXJEYXRhIjpudWxsLCJiZXR3ZWVuTWF0Y2hlckRhdGEiOm51bGwsImJvb2xlYW5NYXRjaGVyRGF0YSI6bnVsbCwiZGVwZW5kZW5jeU1hdGNoZXJEYXRhIjpudWxsLCJzdHJpbmdNYXRjaGVyRGF0YSI6bnVsbH1dfSwicGFydGl0aW9ucyI6W3sidHJlYXRtZW50Ijoib24iLCJzaXplIjoxMDB9LHsidHJlYXRtZW50Ijoib2ZmIiwic2l6ZSI6MH0seyJ0cmVhdG1lbnQiOiJmcmVlIiwic2l6ZSI6MH0seyJ0cmVhdG1lbnQiOiJjb250YSIsInNpemUiOjB9XSwibGFiZWwiOiJkZWZhdWx0IHJ1bGUifV19\\\"}
    """

    static let kFlagSetsNotification4None = """
    {\\\"type\\\":\\\"SPLIT_UPDATE\\\",\\\"changeNumber\\\":4,\\\"pcn\\\":3,\\\"c\\\":0,\\\"d\\\":\\\"eyJ0cmFmZmljVHlwZU5hbWUiOiJjbGllbnQiLCJuYW1lIjoid29ya20iLCJ0cmFmZmljQWxsb2NhdGlvbiI6MTAwLCJ0cmFmZmljQWxsb2NhdGlvblNlZWQiOjE0NzM5MjIyNCwic2VlZCI6NTI0NDE3MTA1LCJzdGF0dXMiOiJBQ1RJVkUiLCJraWxsZWQiOmZhbHNlLCJkZWZhdWx0VHJlYXRtZW50Ijoib24iLCJjaGFuZ2VOdW1iZXIiOjUsImFsZ28iOjIsImNvbmZpZ3VyYXRpb25zIjp7fSwic2V0cyI6W10sImNvbmRpdGlvbnMiOlt7ImNvbmRpdGlvblR5cGUiOiJST0xMT1VUIiwibWF0Y2hlckdyb3VwIjp7ImNvbWJpbmVyIjoiQU5EIiwibWF0Y2hlcnMiOlt7ImtleVNlbGVjdG9yIjp7InRyYWZmaWNUeXBlIjoiY2xpZW50IiwiYXR0cmlidXRlIjpudWxsfSwibWF0Y2hlclR5cGUiOiJJTl9TRUdNRU5UIiwibmVnYXRlIjpmYWxzZSwidXNlckRlZmluZWRTZWdtZW50TWF0Y2hlckRhdGEiOnsic2VnbWVudE5hbWUiOiJuZXdfc2VnbWVudCJ9LCJ3aGl0ZWxpc3RNYXRjaGVyRGF0YSI6bnVsbCwidW5hcnlOdW1lcmljTWF0Y2hlckRhdGEiOm51bGwsImJldHdlZW5NYXRjaGVyRGF0YSI6bnVsbCwiYm9vbGVhbk1hdGNoZXJEYXRhIjpudWxsLCJkZXBlbmRlbmN5TWF0Y2hlckRhdGEiOm51bGwsInN0cmluZ01hdGNoZXJEYXRhIjpudWxsfV19LCJwYXJ0aXRpb25zIjpbeyJ0cmVhdG1lbnQiOiJvbiIsInNpemUiOjB9LHsidHJlYXRtZW50Ijoib2ZmIiwic2l6ZSI6MH0seyJ0cmVhdG1lbnQiOiJmcmVlIiwic2l6ZSI6MTAwfSx7InRyZWF0bWVudCI6ImNvbnRhIiwic2l6ZSI6MH1dLCJsYWJlbCI6ImluIHNlZ21lbnQgbmV3X3NlZ21lbnQifSx7ImNvbmRpdGlvblR5cGUiOiJST0xMT1VUIiwibWF0Y2hlckdyb3VwIjp7ImNvbWJpbmVyIjoiQU5EIiwibWF0Y2hlcnMiOlt7ImtleVNlbGVjdG9yIjp7InRyYWZmaWNUeXBlIjoiY2xpZW50IiwiYXR0cmlidXRlIjpudWxsfSwibWF0Y2hlclR5cGUiOiJBTExfS0VZUyIsIm5lZ2F0ZSI6ZmFsc2UsInVzZXJEZWZpbmVkU2VnbWVudE1hdGNoZXJEYXRhIjpudWxsLCJ3aGl0ZWxpc3RNYXRjaGVyRGF0YSI6bnVsbCwidW5hcnlOdW1lcmljTWF0Y2hlckRhdGEiOm51bGwsImJldHdlZW5NYXRjaGVyRGF0YSI6bnVsbCwiYm9vbGVhbk1hdGNoZXJEYXRhIjpudWxsLCJkZXBlbmRlbmN5TWF0Y2hlckRhdGEiOm51bGwsInN0cmluZ01hdGNoZXJEYXRhIjpudWxsfV19LCJwYXJ0aXRpb25zIjpbeyJ0cmVhdG1lbnQiOiJvbiIsInNpemUiOjEwMH0seyJ0cmVhdG1lbnQiOiJvZmYiLCJzaXplIjowfSx7InRyZWF0bWVudCI6ImZyZWUiLCJzaXplIjowfSx7InRyZWF0bWVudCI6ImNvbnRhIiwic2l6ZSI6MH1dLCJsYWJlbCI6ImRlZmF1bHQgcnVsZSJ9XX0\\\"}
    """

    static let kFlagSetsNotification4 = """
    {\\\"type\\\":\\\"SPLIT_UPDATE\\\",\\\"changeNumber\\\":4,\\\"pcn\\\":3,\\\"c\\\":0,\\\"d\\\":\\\"eyJ0cmFmZmljVHlwZU5hbWUiOiJjbGllbnQiLCJuYW1lIjoid29ya20iLCJ0cmFmZmljQWxsb2NhdGlvbiI6MTAwLCJ0cmFmZmljQWxsb2NhdGlvblNlZWQiOjE0NzM5MjIyNCwic2VlZCI6NTI0NDE3MTA1LCJzdGF0dXMiOiJBQ1RJVkUiLCJraWxsZWQiOmZhbHNlLCJkZWZhdWx0VHJlYXRtZW50Ijoib24iLCJjaGFuZ2VOdW1iZXIiOjQsImFsZ28iOjIsImNvbmZpZ3VyYXRpb25zIjp7fSwic2V0cyI6WyJzZXRfMyJdLCJjb25kaXRpb25zIjpbeyJjb25kaXRpb25UeXBlIjoiUk9MTE9VVCIsIm1hdGNoZXJHcm91cCI6eyJjb21iaW5lciI6IkFORCIsIm1hdGNoZXJzIjpbeyJrZXlTZWxlY3RvciI6eyJ0cmFmZmljVHlwZSI6ImNsaWVudCIsImF0dHJpYnV0ZSI6bnVsbH0sIm1hdGNoZXJUeXBlIjoiSU5fU0VHTUVOVCIsIm5lZ2F0ZSI6ZmFsc2UsInVzZXJEZWZpbmVkU2VnbWVudE1hdGNoZXJEYXRhIjp7InNlZ21lbnROYW1lIjoibmV3X3NlZ21lbnQifSwid2hpdGVsaXN0TWF0Y2hlckRhdGEiOm51bGwsInVuYXJ5TnVtZXJpY01hdGNoZXJEYXRhIjpudWxsLCJiZXR3ZWVuTWF0Y2hlckRhdGEiOm51bGwsImJvb2xlYW5NYXRjaGVyRGF0YSI6bnVsbCwiZGVwZW5kZW5jeU1hdGNoZXJEYXRhIjpudWxsLCJzdHJpbmdNYXRjaGVyRGF0YSI6bnVsbH1dfSwicGFydGl0aW9ucyI6W3sidHJlYXRtZW50Ijoib24iLCJzaXplIjowfSx7InRyZWF0bWVudCI6Im9mZiIsInNpemUiOjB9LHsidHJlYXRtZW50IjoiZnJlZSIsInNpemUiOjEwMH0seyJ0cmVhdG1lbnQiOiJjb250YSIsInNpemUiOjB9XSwibGFiZWwiOiJpbiBzZWdtZW50IG5ld19zZWdtZW50In0seyJjb25kaXRpb25UeXBlIjoiUk9MTE9VVCIsIm1hdGNoZXJHcm91cCI6eyJjb21iaW5lciI6IkFORCIsIm1hdGNoZXJzIjpbeyJrZXlTZWxlY3RvciI6eyJ0cmFmZmljVHlwZSI6ImNsaWVudCIsImF0dHJpYnV0ZSI6bnVsbH0sIm1hdGNoZXJUeXBlIjoiQUxMX0tFWVMiLCJuZWdhdGUiOmZhbHNlLCJ1c2VyRGVmaW5lZFNlZ21lbnRNYXRjaGVyRGF0YSI6bnVsbCwid2hpdGVsaXN0TWF0Y2hlckRhdGEiOm51bGwsInVuYXJ5TnVtZXJpY01hdGNoZXJEYXRhIjpudWxsLCJiZXR3ZWVuTWF0Y2hlckRhdGEiOm51bGwsImJvb2xlYW5NYXRjaGVyRGF0YSI6bnVsbCwiZGVwZW5kZW5jeU1hdGNoZXJEYXRhIjpudWxsLCJzdHJpbmdNYXRjaGVyRGF0YSI6bnVsbH1dfSwicGFydGl0aW9ucyI6W3sidHJlYXRtZW50Ijoib24iLCJzaXplIjoxMDB9LHsidHJlYXRtZW50Ijoib2ZmIiwic2l6ZSI6MH0seyJ0cmVhdG1lbnQiOiJmcmVlIiwic2l6ZSI6MH0seyJ0cmVhdG1lbnQiOiJjb250YSIsInNpemUiOjB9XSwibGFiZWwiOiJkZWZhdWx0IHJ1bGUifV19\\\"}
    """

    static let kFlagSetsNotification5 = """
    {\\\"type\\\":\\\"SPLIT_UPDATE\\\",\\\"changeNumber\\\":5,\\\"pcn\\\":4,\\\"c\\\":0,\\\"d\\\":\\\"eyJ0cmFmZmljVHlwZU5hbWUiOiJjbGllbnQiLCJuYW1lIjoid29ya20iLCJ0cmFmZmljQWxsb2NhdGlvbiI6MTAwLCJ0cmFmZmljQWxsb2NhdGlvblNlZWQiOjE0NzM5MjIyNCwic2VlZCI6NTI0NDE3MTA1LCJzdGF0dXMiOiJBQ1RJVkUiLCJraWxsZWQiOmZhbHNlLCJkZWZhdWx0VHJlYXRtZW50Ijoib24iLCJjaGFuZ2VOdW1iZXIiOjUsImFsZ28iOjIsImNvbmZpZ3VyYXRpb25zIjp7fSwic2V0cyI6WyJzZXRfMyIsInNldF80Il0sImNvbmRpdGlvbnMiOlt7ImNvbmRpdGlvblR5cGUiOiJST0xMT1VUIiwibWF0Y2hlckdyb3VwIjp7ImNvbWJpbmVyIjoiQU5EIiwibWF0Y2hlcnMiOlt7ImtleVNlbGVjdG9yIjp7InRyYWZmaWNUeXBlIjoiY2xpZW50IiwiYXR0cmlidXRlIjpudWxsfSwibWF0Y2hlclR5cGUiOiJJTl9TRUdNRU5UIiwibmVnYXRlIjpmYWxzZSwidXNlckRlZmluZWRTZWdtZW50TWF0Y2hlckRhdGEiOnsic2VnbWVudE5hbWUiOiJuZXdfc2VnbWVudCJ9LCJ3aGl0ZWxpc3RNYXRjaGVyRGF0YSI6bnVsbCwidW5hcnlOdW1lcmljTWF0Y2hlckRhdGEiOm51bGwsImJldHdlZW5NYXRjaGVyRGF0YSI6bnVsbCwiYm9vbGVhbk1hdGNoZXJEYXRhIjpudWxsLCJkZXBlbmRlbmN5TWF0Y2hlckRhdGEiOm51bGwsInN0cmluZ01hdGNoZXJEYXRhIjpudWxsfV19LCJwYXJ0aXRpb25zIjpbeyJ0cmVhdG1lbnQiOiJvbiIsInNpemUiOjB9LHsidHJlYXRtZW50Ijoib2ZmIiwic2l6ZSI6MH0seyJ0cmVhdG1lbnQiOiJmcmVlIiwic2l6ZSI6MTAwfSx7InRyZWF0bWVudCI6ImNvbnRhIiwic2l6ZSI6MH1dLCJsYWJlbCI6ImluIHNlZ21lbnQgbmV3X3NlZ21lbnQifSx7ImNvbmRpdGlvblR5cGUiOiJST0xMT1VUIiwibWF0Y2hlckdyb3VwIjp7ImNvbWJpbmVyIjoiQU5EIiwibWF0Y2hlcnMiOlt7ImtleVNlbGVjdG9yIjp7InRyYWZmaWNUeXBlIjoiY2xpZW50IiwiYXR0cmlidXRlIjpudWxsfSwibWF0Y2hlclR5cGUiOiJBTExfS0VZUyIsIm5lZ2F0ZSI6ZmFsc2UsInVzZXJEZWZpbmVkU2VnbWVudE1hdGNoZXJEYXRhIjpudWxsLCJ3aGl0ZWxpc3RNYXRjaGVyRGF0YSI6bnVsbCwidW5hcnlOdW1lcmljTWF0Y2hlckRhdGEiOm51bGwsImJldHdlZW5NYXRjaGVyRGF0YSI6bnVsbCwiYm9vbGVhbk1hdGNoZXJEYXRhIjpudWxsLCJkZXBlbmRlbmN5TWF0Y2hlckRhdGEiOm51bGwsInN0cmluZ01hdGNoZXJEYXRhIjpudWxsfV19LCJwYXJ0aXRpb25zIjpbeyJ0cmVhdG1lbnQiOiJvbiIsInNpemUiOjEwMH0seyJ0cmVhdG1lbnQiOiJvZmYiLCJzaXplIjowfSx7InRyZWF0bWVudCI6ImZyZWUiLCJzaXplIjowfSx7InRyZWF0bWVudCI6ImNvbnRhIiwic2l6ZSI6MH1dLCJsYWJlbCI6ImRlZmF1bHQgcnVsZSJ9XX0\\\"}
    """

    static let kFlagSetsNotificationKill = """
    {\\\"type\\\":\\\"SPLIT_KILL\\\",\\\"changeNumber\\\":5,\\\"defaultTreatment\\\":\\\"off\\\",\\\"splitName\\\":\\\"workm\\\"}
    """

    // MARK: Functions

    static func escapedUpdateSplitsNotificationGzip(pcn: Int) -> String {
        return """
        {\\\"type\\\":\\\"SPLIT_UPDATE\\\",\\\"changeNumber\\\":1684265694505,\\\"pcn\\\":\(
            pcn),\\\"c\\\":1,\\\"d\\\":\\\"H4sIAAAAAAAA/8yT327aTBDFXyU612vJxoTgvUMfKB8qcaSapqoihAZ7DNusvWi9TpUiv3tl/pdQVb1qL+cwc3bOj/EGzlKeq3T6tuaYCoZEXbGFgMogkXXDIM0y31v4C/aCgMnrU9/3gl7Pp4yilMMIAuVusqDamvlXeiWIg/FAa5OSU6aEDHz/ip4wZ5Be1AmjoBsFAtVOCO56UXh31/O7ApUjV1eQGPw3HT+NIPCitG7bctIVC2ScU63d1DK5gksHCZPnEEhXVC45rosFW8ig1++GYej3g85tJEB6aSA7Aqkpc7Ws7XahCnLTbLVM7evnzalsUUHi8//j6WgyTqYQKMilK7b31tRryLa3WKiyfRCDeHhq2Dntiys+JS/J8THUt5VyrFXlHnYTQ3LU2h91yGdQVqhy+0RtTeuhUoNZ08wagTVZdxbBndF5vYVApb7z9m9pZgKaFqwhT+6coRHvg398nEweP/157Bd+S1hz6oxtm88O73B0jbhgM47nyej+YRRfgdNODDlXJWcJL9tUF5SqnRqfbtPr4LdcTHnk4rfp3buLOkG7+Pmp++vRM9w/wVblzX7Pm8OGfxf5YDKZfxh9SS6B/2Pc9t/7ja01o5k1PwIAAP//uTipVskEAAA=\\\"}
        """
    }

    static func flagSetsNotification(pcn: Int) -> String {
        return """
            {\\\"type\\\":\\\"SPLIT_UPDATE\\\",\\\"changeNumber\\\":2,\\\"pcn\\\":\(
                pcn),\\\"c\\\":0,\\\"d\\\":\\\"eyJ0cmFmZmljVHlwZU5hbWUiOiJjbGllbnQiLCJuYW1lIjoid29ya20iLCJ0cmFmZmljQWxsb2NhdGlvbiI6MTAwLCJ0cmFmZmljQWxsb2NhdGlvblNlZWQiOjE0NzM5MjIyNCwic2VlZCI6NTI0NDE3MTA1LCJzdGF0dXMiOiJBQ1RJVkUiLCJraWxsZWQiOmZhbHNlLCJkZWZhdWx0VHJlYXRtZW50Ijoib24iLCJjaGFuZ2VOdW1iZXIiOjIsImFsZ28iOjIsImNvbmZpZ3VyYXRpb25zIjp7fSwic2V0cyI6WyJzZXRfMSIsInNldF8yIl0sImNvbmRpdGlvbnMiOlt7ImNvbmRpdGlvblR5cGUiOiJST0xMT1VUIiwibWF0Y2hlckdyb3VwIjp7ImNvbWJpbmVyIjoiQU5EIiwibWF0Y2hlcnMiOlt7ImtleVNlbGVjdG9yIjp7InRyYWZmaWNUeXBlIjoiY2xpZW50IiwiYXR0cmlidXRlIjpudWxsfSwibWF0Y2hlclR5cGUiOiJJTl9TRUdNRU5UIiwibmVnYXRlIjpmYWxzZSwidXNlckRlZmluZWRTZWdtZW50TWF0Y2hlckRhdGEiOnsic2VnbWVudE5hbWUiOiJuZXdfc2VnbWVudCJ9LCJ3aGl0ZWxpc3RNYXRjaGVyRGF0YSI6bnVsbCwidW5hcnlOdW1lcmljTWF0Y2hlckRhdGEiOm51bGwsImJldHdlZW5NYXRjaGVyRGF0YSI6bnVsbCwiYm9vbGVhbk1hdGNoZXJEYXRhIjpudWxsLCJkZXBlbmRlbmN5TWF0Y2hlckRhdGEiOm51bGwsInN0cmluZ01hdGNoZXJEYXRhIjpudWxsfV19LCJwYXJ0aXRpb25zIjpbeyJ0cmVhdG1lbnQiOiJvbiIsInNpemUiOjB9LHsidHJlYXRtZW50Ijoib2ZmIiwic2l6ZSI6MH0seyJ0cmVhdG1lbnQiOiJmcmVlIiwic2l6ZSI6MTAwfSx7InRyZWF0bWVudCI6ImNvbnRhIiwic2l6ZSI6MH1dLCJsYWJlbCI6ImluIHNlZ21lbnQgbmV3X3NlZ21lbnQifSx7ImNvbmRpdGlvblR5cGUiOiJST0xMT1VUIiwibWF0Y2hlckdyb3VwIjp7ImNvbWJpbmVyIjoiQU5EIiwibWF0Y2hlcnMiOlt7ImtleVNlbGVjdG9yIjp7InRyYWZmaWNUeXBlIjoiY2xpZW50IiwiYXR0cmlidXRlIjpudWxsfSwibWF0Y2hlclR5cGUiOiJBTExfS0VZUyIsIm5lZ2F0ZSI6ZmFsc2UsInVzZXJEZWZpbmVkU2VnbWVudE1hdGNoZXJEYXRhIjpudWxsLCJ3aGl0ZWxpc3RNYXRjaGVyRGF0YSI6bnVsbCwidW5hcnlOdW1lcmljTWF0Y2hlckRhdGEiOm51bGwsImJldHdlZW5NYXRjaGVyRGF0YSI6bnVsbCwiYm9vbGVhbk1hdGNoZXJEYXRhIjpudWxsLCJkZXBlbmRlbmN5TWF0Y2hlckRhdGEiOm51bGwsInN0cmluZ01hdGNoZXJEYXRhIjpudWxsfV19LCJwYXJ0aXRpb25zIjpbeyJ0cmVhdG1lbnQiOiJvbiIsInNpemUiOjEwMH0seyJ0cmVhdG1lbnQiOiJvZmYiLCJzaXplIjowfSx7InRyZWF0bWVudCI6ImZyZWUiLCJzaXplIjowfSx7InRyZWF0bWVudCI6ImNvbnRhIiwic2l6ZSI6MH1dLCJsYWJlbCI6ImRlZmF1bHQgcnVsZSJ9XX0\\\"}
        """
    }

    static func encodedKeyListPayloadGzip() -> String {
        do {
            let notification = try Json.decodeFrom(
                json: kKeyListNotificationGzip,
                to: MembershipsUpdateNotification.self)
            return notification.data ?? ""
        } catch {
            print("encodedKeyListPayloadGzip \(error)")
        }
        return ""
    }

    static func encodedBoundedPayloadGzip() -> String {
        do {
            let notification = try Json.decodeFrom(
                json: kBoundedNotificationGzip,
                to: MembershipsUpdateNotification.self)
            return notification.data ?? ""
        } catch {
            print("encodedBoundedPayloadGzip \(error)")
        }
        return ""
    }

    static func encodedBoundedPayloadZlib() -> String {
        do {
            let notification = try Json.decodeFrom(
                json: kBoundedNotificationZlib,
                to: MembershipsUpdateNotification.self)
            return notification.data ?? ""
        } catch {
            print("encodedBoundedPayloadZlib \(error)")
        }
        return ""
    }

    static func updateSplitsNotificationZlib() -> TargetingRuleUpdateNotification {
        return try! Json.decodeFrom(json: kUpdateSplitsNotificationZlib, to: TargetingRuleUpdateNotification.self)
    }

    static func updateSplitsNotificationGzip() -> TargetingRuleUpdateNotification {
        return try! Json.decodeFrom(json: kUpdateSplitsNotificationGzip, to: TargetingRuleUpdateNotification.self)
    }

    static func membershipsNotificationUnboundedMessage(
        type: NotificationType,
        cn: Int64? = nil,
        delay: Int = 100) -> String {
        let changeNumber = cn ?? 1702507130121
        let strType = (NotificationType.mySegmentsUpdate == type ? "memberships_ms_update" : "memberships_ls_update")
        var data = "\"{\\\"type\\\":\\\"\(strType)\\\",\\\"c\\\":2,\\\"u\\\":0}\""
        if type == .myLargeSegmentsUpdate {
            data =
                "\"{\\\"type\\\":\\\"\(strType)\\\",\\\"cn\\\":\(changeNumber),\\\"c\\\":2,\\\"u\\\":0, \\\"i\\\": \(delay)}\""
        }

        let message = """
            {
              \"id\": \"diSrQttrC9:0:0\",
              \"clientId\": \"pri:MjcyNDE2NDUxMA==\",
              \"timestamp\": 1702507131100,
              \"encoding\": \"json\",
              \"channel\": \"NzM2MDI5Mzc0_MTc1MTYwODQxMQ==memberships\",
              \"data\": \(data)
            }
        """
        return message
    }

    static func fullMembershipsNotificationUnboundedMessage(
        type: NotificationType,
        cn: Int64? = nil,
        delay: Int = 100) -> String {
        let data = membershipsNotificationUnboundedMessage(type: type, delay: delay)
        let msg = """
               id:cf74eb42-f687-48e4-ad18-af2125110aac
               event:message
               data:\(data.replacingOccurrences(of: "\n", with: ""))
        """

        return msg
    }

    static func membershipsNotificationSegmentRemovalMessage(type: NotificationType) -> String {
        let strType = (NotificationType.mySegmentsUpdate == type ? "memberships_ms_update" : "memberships_ls_update")
        var data =
            "\"{\\\"type\\\":\\\"\(strType)\\\",\\\"cn\\\":1702507130121,\\\"u\\\":3,\\\"c\\\":0, \\\"n\\\":[\\\"android_test\\\", \\\"ios_test\\\"]}\""
        if type == .mySegmentsUpdate {
            data =
                "\"{\\\"type\\\":\\\"\(strType)\\\",\\\"u\\\":3,\\\"c\\\":0, \\\"n\\\":[\\\"android_test\\\", \\\"ios_test\\\"]}\""
        }

        let message = """
            {
              \"id\": \"diSrQttrC9:0:0\",
              \"clientId\": \"pri:MjcyNDE2NDUxMA==\",
              \"timestamp\": 1702507131100,
              \"encoding\": \"json\",
              \"channel\": \"NzM2MDI5Mzc0_MTc1MTYwODQxMQ==memberships\",
              \"data\": \(data)
            }
        """
        return message
    }

    static func membershipsNotificationSegmentRemovalMessage(
        type: NotificationType,
        segment: String,
        timestamp: Int) -> String {
        let strType = (NotificationType.mySegmentsUpdate == type ? "memberships_ms_update" : "memberships_ls_update")
        var data =
            "\"{\\\"type\\\":\\\"\(strType)\\\",\\\"cn\\\":1702507130121,\\\"u\\\":3,\\\"c\\\":0, \\\"n\\\":[\\\"\(segment)\\\"]}\""
        if type == .mySegmentsUpdate {
            data = "\"{\\\"type\\\":\\\"\(strType)\\\",\\\"u\\\":3,\\\"c\\\":0, \\\"n\\\":[\\\"\(segment)\\\"]}\""
        }

        let message = """
            {
              \"id\": \"diSrQttrC9:0:0\",
              \"clientId\": \"pri:MjcyNDE2NDUxMA==\",
              \"timestamp\": \(timestamp),
              \"encoding\": \"json\",
              \"channel\": \"NzM2MDI5Mzc0_MTc1MTYwODQxMQ==memberships\",
              \"data\": \(data)
            }
        """
        let msg = """
               id:cf74eb42-f687-48e4-ad18-af2125110aac
               event:message
               data:\(message.replacingOccurrences(of: "\n", with: ""))
        """

        return msg
    }

    static func membershipsNotificationAllFieldsMessage(type: NotificationType) -> String {
        let strType = (NotificationType.mySegmentsUpdate == type ? "memberships_ms_update" : "memberships_ls_update")
        var data =
            "\"{\\\"type\\\":\\\"\(strType)\\\",\\\"c\\\":2,\\\"u\\\":0,\\\"n\\\": [\\\"test\\\"], \\\"d\\\":\\\"eJwEwLsRwzAMA9BdWKsg+IFBraJTkRXS5rK7388+tg+KdC8+jq4eBBQLFcUnO8FAAC36gndOSEyFqJFP32Vf2+f+3wAAAP//hUQQ9A==\\\"}\""

        if type == .myLargeSegmentsUpdate {
            data =
                "\"{\\\"type\\\":\\\"\(strType)\\\",\\\"cn\\\":1702507130121,\\\"c\\\":2,\\\"s\\\":200,\\\"u\\\":0,\\\"h\\\":0,\\\"i\\\": 300,\\\"n\\\": [\\\"test\\\"], \\\"d\\\":\\\"eJwEwLsRwzAMA9BdWKsg+IFBraJTkRXS5rK7388+tg+KdC8+jq4eBBQLFcUnO8FAAC36gndOSEyFqJFP32Vf2+f+3wAAAP//hUQQ9A==\\\"}\""
        }

        let message = """

            {
              \"id\": \"diSrQttrC9:0:0\",
              \"clientId\": \"pri:MjcyNDE2NDUxMA==\",
              \"timestamp\": 1702507131100,
              \"encoding\": \"json\",
              \"channel\": \"NzM2MDI5Mzc0_MTc1MTYwODQxMQ==memberships\",
              \"data\": \(data)
            }
        """
        return message
    }

    static func rbsChange(
        changeNumber: Int64,
        previousChangeNumber: Int64,
        compressionType: Int,
        compressedPayload: String) -> String {
        return """
        id: 123123
        event: message
        data: {\"id\":\"1111\",\"clientId\":\"pri:ODc1NjQyNzY1\",\"timestamp\":\(
            Date
                .now(
                )),\"encoding\":\"json\",\"channel\":\"xxxx_xxxx_flags\",\"data\":\"{\\\"type\\\":\\\"RB_SEGMENT_UPDATE\\\",\\\"changeNumber\\\":\(
            changeNumber),\\\"pcn\\\":\(
            previousChangeNumber),\\\"c\\\": \(compressionType),\\\"d\\\":\\\"\(compressedPayload)\\\"}\"}
        """
    }
}
