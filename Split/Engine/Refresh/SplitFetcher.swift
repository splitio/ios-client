//
//  SplitFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 5/10/17.
//
//

import Foundation

@objc public protocol SplitFetcher {
    
    func fetch(splitName: String) -> ParsedSplit
    
    func fetchAll() -> [ParsedSplit]
    
    func forceRefresh()
    
}
