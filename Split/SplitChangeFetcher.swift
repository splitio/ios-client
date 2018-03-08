//
//  SplitChangeFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 19/9/17.
//
//

import Foundation

public protocol SplitChangeFetcher {
    func fetch(since: Int64, policy: FecthingPolicy) throws -> SplitChange
}


public extension SplitChangeFetcher {
    func fetch(since: Int64, policy: FecthingPolicy = .networkAndCache) throws -> SplitChange {
         return try fetch(since: since, policy: policy)
    }
}
