//
//  DependencyMatcherData.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc class DependencyMatcherData: NSObject, Codable, @unchecked Sendable {
    var split: String?
    var treatments: [String]?
}
