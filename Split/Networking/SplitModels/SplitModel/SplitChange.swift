//
//  SplitChange.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc public class SplitChange: NSObject, Codable {
    
    var splits: [Split]?
    var since: Int64?
    var till: Int64?

}
