//
//  MatcherCombiner.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc public enum MatcherCombiner: Int, Codable {
    case And
    
    public typealias RawValue = Int
    
    enum CodingKeys: String, CodingKey {
        case intValue
    }
    
    public init(from decoder: Decoder) throws {
        self = MatcherCombiner.enumFromString(string: "and")!
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("and")
    }
    
    static func enumFromString(string: String) -> MatcherCombiner? {
        switch string.lowercased() {
        case "and":
            return MatcherCombiner.And
       
        default:
            return nil
        }
    }
    
    public func combineAndResults(partialResults:[Bool]) -> Bool {
        
        for result in partialResults {
            
            if result == false {
                
                return false
            }
        }
        
        return true
        
    }
}
