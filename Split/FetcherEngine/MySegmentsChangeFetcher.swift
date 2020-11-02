//
//  MySegmentsFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 29/9/17.
//
//

import Foundation

protocol MySegmentsChangeFetcher {
    func fetch(user: String, policy: FecthingPolicy) throws -> [String]?
}

extension MySegmentsChangeFetcher {
    func fetch(user: String, policy: FecthingPolicy = .networkAndCache) throws -> [String]? {
        return try fetch(user: user, policy: policy)
    }
}
