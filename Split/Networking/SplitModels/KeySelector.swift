//
//  KeySelector.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
import SwiftyJSON

@objc public class KeySelector: NSObject {
    
    var trafficType: String?
    var attribute: String?
    
    public init(_ json: JSON) {
        self.trafficType = json["trafficType"] != JSON.null ? json["trafficType"].stringValue : nil
        self.attribute = json["attribute"] != JSON.null ? json["attribute"].stringValue : nil
    }
}
