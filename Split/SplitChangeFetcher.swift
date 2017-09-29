//
//  SplitChangeFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 19/9/17.
//
//

import Foundation

@objc public protocol SplitChangeFetcher {
    
    func fetch(since: Int64) throws -> SplitChange
}
