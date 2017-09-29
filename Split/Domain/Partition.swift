//
//  Partition.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
import SwiftyJSON

@objc public class Partition: NSObject {
    
    var treatment: String?
    var size: Int?
    
    public init(_ json: JSON) {
        self.treatment = json["treatment"].stringValue
        self.size = json["size"].intValue
    }
    
}
