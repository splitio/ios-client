//
//  MySegmentsFetcherProtocol.swift
//  Pods
//
//  Created by Brian Sztamfater on 5/10/17.
//
//

import Foundation

protocol MySegmentsFetcher {
    func runInitialFetch()
    func fetchAll() -> [String]
    func forceRefresh()
}

protocol RefreshableMySegmentsFetcher: MySegmentsFetcher, PeriodicTask {
}
