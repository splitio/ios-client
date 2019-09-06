//
//  BetweenMatcherData.swift
//  Split
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc class BetweenMatcherData: NSObject, Codable {
    var dataType: DataType?
    var start: Int64?
    var end: Int64?
}
