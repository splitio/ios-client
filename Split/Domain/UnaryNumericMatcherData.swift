//
//  UnaryNumericMatcherData.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
import SwiftyJSON

@objc public class UnaryNumericMatcherData: NSObject {

    var dataType: DataType?
    var value: Int64?
    
    public init(_ json: JSON) {
        self.dataType = DataType.enumFromString(string: json["dataType"].stringValue)
        self.value = json["value"].int64Value
    }
}
