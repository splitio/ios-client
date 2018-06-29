//
//  MatcherGroup.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc public class MatcherGroup: NSObject, Codable {
    
    public var matcherCombiner: MatcherCombiner?
    public var matchers: [Matcher]?
    
    enum CodingKeys: String, CodingKey {
        case matcherCombiner = "combiner"
        case matchers
    }
    
    public required init(from decoder: Decoder) throws {
        if let values = try? decoder.container(keyedBy: CodingKeys.self) {
            matcherCombiner = try? values.decode(MatcherCombiner.self, forKey: .matcherCombiner)
            matchers = try? values.decode([Matcher].self, forKey: .matchers)
        }
    }
    
}
