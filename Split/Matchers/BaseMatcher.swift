//
//  BaseMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/5/17.
//

import Foundation


public class BaseMatcher : NSObject  {
    
    var splitClient: SplitClient?
    var negate: Bool?
    var atributte: String?
    var type: MatcherType?
    
    //--------------------------------------------------------------------------------------------------
    public init(splitClient: SplitClient? = nil, negate: Bool? = nil, atributte: String? = nil , type: MatcherType? = nil) {

        self.splitClient = splitClient
        self.negate = negate
        self.atributte = atributte
        self.type = type
        
    }
    //--------------------------------------------------------------------------------------------------
    public func isNegate() -> Bool {
        
        return self.negate!
    }
    //--------------------------------------------------------------------------------------------------
    public func hasAttribute() -> Bool {
        
        return self.atributte != nil
        
    }
    //--------------------------------------------------------------------------------------------------
    public func getAttribute() -> String? {
        
        return self.atributte
        
    }
    //--------------------------------------------------------------------------------------------------
    public func getMatcherType() -> MatcherType {
        
        return self.type!
        
    }
    //--------------------------------------------------------------------------------------------------
    public func matcherHasAttribute() -> Bool {
        
        return self.atributte != nil
        
    }
    //--------------------------------------------------------------------------------------------------

}
