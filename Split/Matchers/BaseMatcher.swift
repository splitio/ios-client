//
//  BaseMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/5/17.
//

import Foundation


public class BaseMatcher : NSObject  {
    
    public var splitClient: DefaultSplitClient?
    var negate: Bool?
    var attribute: String?
    var type: MatcherType?
    
    //--------------------------------------------------------------------------------------------------
    public init(splitClient: DefaultSplitClient? = nil, negate: Bool? = nil, attribute: String? = nil , type: MatcherType? = nil) {

        self.splitClient = splitClient
        self.negate = negate
        self.attribute = attribute
        self.type = type
        
    }
    //--------------------------------------------------------------------------------------------------
    public func isNegate() -> Bool {
        
        return self.negate!
    }
    //--------------------------------------------------------------------------------------------------
    public func hasAttribute() -> Bool {
        
        return self.attribute != nil
        
    }
    //--------------------------------------------------------------------------------------------------
    public func getAttribute() -> String? {
        
        return self.attribute
        
    }
    //--------------------------------------------------------------------------------------------------
    public func getMatcherType() -> MatcherType {
        
        return self.type!
        
    }
    //--------------------------------------------------------------------------------------------------
    public func matcherHasAttribute() -> Bool {
        
        return self.attribute != nil
        
    }
    //--------------------------------------------------------------------------------------------------

}
