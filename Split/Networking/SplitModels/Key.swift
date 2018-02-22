//
//  SplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation
import SwiftyJSON


public class Key: NSObject {
    
    let matchingKey: String
    let bucketingKey: String?

    public init(matchingKey: String, bucketingKey: String? = nil) {
        self.matchingKey = matchingKey
        self.bucketingKey = bucketingKey
    }
    
    func toJSON() -> JSON {
        var json = JSON(["matchingKey" : self.matchingKey])
        if self.bucketingKey != nil {
            json["bucketingKey"].stringValue = self.bucketingKey!
        }
        return json
    }
}
