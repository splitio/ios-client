//
//  SplitChangeFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 19/9/17.
//
//

import Foundation

@available(*, deprecated, message: "To be removed in integration PR")
protocol SplitChangeFetcher {
    func fetch(since: Int64, policy: FecthingPolicy, clearCache: Bool) throws -> SplitChange?
}

//extension SplitChangeFetcher {
//    func fetch(since: Int64, policy: FecthingPolicy = .networkAndCache, clearCache: Bool = false)
//        throws -> SplitChange? {
//        return try fetch(since: since, policy: policy, clearCache: clearCache)
//    }
//}
