//
//  SplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation
import SwiftyJSON

@objc public class Key: NSObject {
    
    let matchingKey: String
    let trafficType: String
    let bucketingKey: String?

    public init(matchingKey: String, trafficType: String, bucketingKey: String? = nil) {
        self.matchingKey = matchingKey
        self.trafficType = trafficType
        self.bucketingKey = bucketingKey
    }
    
    func toJSON() -> JSON {
        var json = JSON(["matchingKey" : self.matchingKey, "trafficType" : self.trafficType])
        if self.bucketingKey != nil {
            json["bucketingKey"].stringValue = self.bucketingKey!
        }
        return json
    }
}
