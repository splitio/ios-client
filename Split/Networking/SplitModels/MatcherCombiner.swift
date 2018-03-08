//
//  MatcherCombiner.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc public enum MatcherCombiner: Int {
    case And
    
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
