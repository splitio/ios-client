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
        self.name = json["splitName"].string
        self.treatment = json["treatment"].string
    }
}
