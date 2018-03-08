//
//  UserDefinedSegentMatcherdata.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
import SwiftyJSON

@objc public class UserDefinedSegmentMatcherData: NSObject {
    
    var segmentName: String?
    
    public init(_ json: JSON) {
        self.segmentName = json["segmentName"].string
    }
    
}
