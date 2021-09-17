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

    static func encodedKeyListPayloadGzip() -> String {
        do {
            let keyList = try Json.encodeFrom(json: kKeyListNotificationGzip, to: MySegmentsUpdateV2Notification.self)
            return keyList.data ?? ""
        } catch {
            print("encodedKeyListPayloadGzip \(error)")
        }
        return ""
    }
}
