//
//  MySegmentsFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 29/9/17.
//
//

import Foundation

@objc public protocol MySegmentsFetcher {
    
    func fetch(user: String) throws -> [String]
    
}
