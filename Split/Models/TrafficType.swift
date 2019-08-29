//
//  TrafficType.swift
//  Split
//
//  Created by Brian Sztamfater on 21/9/17.
//
//

import Foundation

@objc class TrafficType: NSObject {

    let key: Key
    let attributes: [String: Any]?

    init(matchingKey: String, type: String, bucketingKey: String? = nil, attributes: [String: Any]? = nil) {
        self.key = Key(matchingKey: matchingKey, bucketingKey: bucketingKey)
        self.attributes = attributes
    }
}
