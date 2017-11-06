//
//  BaseMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/5/17.
//

import Foundation


public class BaseMatcher : NSObject {
    
    var bucketingKey: String?
    var atributtes: [String:Any]?
    var splitClient: SplitClient?
    var negate: Bool?
    
    //--------------------------------------------------------------------------------------------------
    public init(bucketingKey: String? = nil , atributtes: [String:Any]? = nil, splitClient: SplitClient? = nil, negate: Bool? = nil) {
        
        self.bucketingKey = bucketingKey
        self.atributtes = atributtes
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
