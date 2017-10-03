//
//  MySegmentsFetcherProtocol.swift
//  Pods
//
//  Created by Brian Sztamfater on 5/10/17.
//
//

import Foundation

@objc public protocol MySegmentsFetcher {
    
    func fetchAll() -> [String]
    
    func forceRefresh()
    
}
