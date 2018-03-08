//
//  MySegmentsFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 29/9/17.
//
//

import Foundation

@objc public protocol MySegmentsChangeFetcher {
    
    func fetch(user: String) throws -> [String]
    
}
