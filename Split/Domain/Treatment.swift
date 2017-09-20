//
//  Split.swift
//  Pods
//
//  Created by Brian Sztamfater on 19/9/17.
//
//

import Foundation
import SwiftyJSON

@objc public class Treatment: NSObject {
    
    let name: String!
    let treatment: String!
    
    internal init(_ json: JSON) {
        self.name = json["splitName"].stringValue
        self.treatment = json["treatment"].stringValue
    }
    
    internal init(_ dict: [String : AnyObject]) {
        self.name = dict["splitName"]!.stringValue
        self.treatment = dict["treatment"]!.stringValue
    }
}
