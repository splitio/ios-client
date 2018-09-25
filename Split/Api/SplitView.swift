//
//  SplitView.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

@objc public class SplitView: NSObject, Codable {
    
    public var name: String?
    public var trafficType: String?
    public var killed: Bool?
    public var treatments: [String]?
    public var changeNumber: Int64?
    
}
