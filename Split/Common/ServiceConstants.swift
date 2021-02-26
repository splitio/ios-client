//
//  ServiceConstants.swift
//  Split
//
//  Created by Javier Avrudsky on 12/01/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

struct ServiceConstants {
    static let estimatedImpressionSizeInBytes = 150
    static let recordedDataExpirationPeriodInSeconds: Int64 = 3600 * 24 * 90 // 90 days
    static let CacheControlHeader = "Cache-Control"
    static let CacheControlNoCache = "no-cache"
}
