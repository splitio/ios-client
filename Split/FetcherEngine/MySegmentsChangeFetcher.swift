//
//  MySegmentsFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 29/9/17.
//
//

import Foundation

@available(*, deprecated, message: "To be removed in integration PR")
protocol MySegmentsChangeFetcher {
    func fetch(user: String, policy: FecthingPolicy) throws -> [String]?
}

@available(*, deprecated, message: "To be removed in integration PR")
extension MySegmentsChangeFetcher {
    func fetch(user: String, policy: FecthingPolicy = .networkAndCache) throws -> [String]? {
        return try fetch(user: user, policy: policy)
    }
}
