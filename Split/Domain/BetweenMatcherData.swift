//
//  BetweenMatcherData.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
import SwiftyJSON

@objc public class BetweenMatcherData: NSObject {
    
    var dataType: DataType?
    var start: Int64?
    var end: Int64?
    
    public init(_ json: JSON) {
        self.dataType = DataType.enumFromString(string: json["dataType"].stringValue)
        self.start = json["start"].int64
        self.end = json["end"].int64
    }
}
