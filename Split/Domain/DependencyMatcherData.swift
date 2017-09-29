//
//  DependencyMatcherData.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
import SwiftyJSON

@objc public class DependencyMatcherData: NSObject {
    
    var split: String?
    var treatments: [String]?
    
    public init(_ json: JSON) {
        self.split = json["split"].stringValue
        self.treatments = json["treatments"].arrayValue.map { return $0.stringValue }
    }
    
}
