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
    // Estimated size of a UniqueKey having a key of 100 chars and
    // 1000 features of 100 chars each
    static let estimatedUniqueKeySizeInBytes = 120
    static let recordedDataExpirationPeriodInSeconds: Int64 = 3600 * 24 * 90 // 90 days
    static let cacheControlHeader = "Cache-Control"
    static let cacheControlNoCache = "no-cache"
    static let eventsPerPush: Int = 2000
    static let impressionsQueueSize: Int = 30000
    static let defaultDataFolder = "split_data"
    static let cacheExpirationInSeconds = 864000
    static let controlNoCacheHeader = [ServiceConstants.cacheControlHeader: ServiceConstants.cacheControlNoCache]
    static let backgroundSyncPeriod = 15.0 * 60 // 15 min
    static let defaultImpressionCountRowsPop = 200
    static let lastSeenImpressionCachSize = 500
    static let databaseExtension = "sqlite"
    static let defaultSseConnectionDelayInSecs: Int64 = 60
    static let retryTimeInSeconds = 0.5
    static let retryCount = 3

    static let uniqueKeyBulkSize = 50
    static let maxUniqueKeyQueueSize = 30000
}
