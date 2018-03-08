//
//  SplitChange.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
import SwiftyJSON

@objc public class SplitChange: NSObject {
    
    var splits: [Split]?
    var since: Int64?
    var till: Int64?

    public init(_ json: JSON) {
        self.splits = json["splits"].array?.map { (json: JSON) -> Split in
            return Split(json)
        }
        self.since = json["since"].int64
        self.till = json["till"].int64
    }
    
    override init() {
        
    }
    
}
