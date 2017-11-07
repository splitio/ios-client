//
//  BaseMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/5/17.
//

import Foundation


public class BaseMatcher : NSObject {
    
    var splitClient: SplitClient?
    var negate: Bool?
    
    //--------------------------------------------------------------------------------------------------
    public init(splitClient: SplitClient? = nil, negate: Bool? = nil) {

        self.splitClient = splitClient
        self.negate = negate
        
    }
    //--------------------------------------------------------------------------------------------------
    public func negate(value: Bool) -> Bool {
        
        if let negateValue = negate, negateValue {
            
            return !value
        }
        
        return value
    }
    //--------------------------------------------------------------------------------------------------

 
}
