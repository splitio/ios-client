//
//  WhitelistMatcherData.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
import SwiftyJSON

public class WhitelistMatcherData: NSObject {

    var whitelist: [String]?
    
    public init(_ json: JSON) {
        self.whitelist = json["whitelist"].array?.map { $0.stringValue }
    }
}
