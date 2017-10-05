//
//  MatcherGroup.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
import SwiftyJSON

@objc public class MatcherGroup: NSObject {
    
    var matcherCombiner: MatcherCombiner?
    var matchers: [Matcher]?
    
    public init(_ json: JSON) {
        self.matcherCombiner = MatcherCombiner.enumFromString(string: json["combiner"].stringValue)
        self.matchers = json["matchers"].array?.map { (json: JSON) -> Matcher in
            return Matcher(json)
        }
    }
}
