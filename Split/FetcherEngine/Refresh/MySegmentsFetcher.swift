//
//  MySegmentsFetcherProtocol.swift
//  Pods
//
//  Created by Brian Sztamfater on 5/10/17.
//
//

import Foundation
@available(*, deprecated, message: "Storage revamp")
protocol MySegmentsFetcher {
    func fetchAll() -> [String]
    func forceRefresh()
}

@available(*, deprecated, message: "Storage revamp")
protocol RefreshableMySegmentsFetcher: MySegmentsFetcher, PeriodicTask {
}
