//
//  SplitFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 5/10/17.
//
//

import Foundation

protocol SplitFetcher {
    func fetch(splitName: String) -> Split?
    func fetchAll() -> [Split]?
    func forceRefresh()
}

protocol RefreshableSplitFetcher: SplitFetcher, PeriodicTask {
}
