//
//  UserDefinedSegentMatcherdata.swift
//  Split
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

class UserDefinedBaseSegmentMatcherData: Codable {
    var segmentName: String?
    var largeSegmentName: String?
}

class UserDefinedSegmentMatcherData: UserDefinedBaseSegmentMatcherData {}

class UserDefinedLargeSegmentMatcherData: UserDefinedBaseSegmentMatcherData {}
