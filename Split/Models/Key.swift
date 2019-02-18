//
//  SplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation

public class Key: NSObject {

    let matchingKey: String
    let bucketingKey: String?

    @objc(initWithMatchingKey:bucketingKey:) public init(matchingKey: String, bucketingKey: String? = nil) {
        self.matchingKey = matchingKey
        self.bucketingKey = bucketingKey
    }
}
