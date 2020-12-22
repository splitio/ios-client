//
//  SplitFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 5/10/17.
//
//

import Foundation
@available(*, deprecated, message: "Storage revamp")
protocol SplitFetcher {
    func fetch(splitName: String) -> Split?
    func fetchAll() -> [Split]?
    func forceRefresh()
}
@available(*, deprecated, message: "Storage revamp")
protocol RefreshableSplitFetcher: SplitFetcher, PeriodicTask {
}
