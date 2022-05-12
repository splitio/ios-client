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

    override public var hash: Int {
        var hasher = Hasher()
        hasher.combine(matchingKey)
        hasher.combine(bucketingKey)
        return hasher.finalize()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Key else {
            return false
        }
        return matchingKey == other.matchingKey
        && bucketingKey == other.bucketingKey
    }

    public override var description: String {
            return "Key: \(matchingKey) - Bucketing: \(bucketingKey ?? "No bucketing")"
        }
}
