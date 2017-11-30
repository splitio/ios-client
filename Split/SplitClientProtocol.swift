//
//  SplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation

public protocol SplitClientProtocol {
    
    func getTreatment(key:Key, split: String, atributtes:[String:Any]?) throws -> String

}


public extension SplitClientProtocol {
    
    func getTreatment(key:Key, split: String, atributtes:[String:Any]? = nil) throws -> String {
        
        return try getTreatment(key: key, split: split, atributtes: atributtes)
        
    }
    
    func getTreatment(key: String, split: String, atributtes:[String:Any]? = nil) -> String {
        
        let composeKey: Key = Key(matchingKey: key, trafficType: "user", bucketingKey: key)
        
        do {
            
            return try getTreatment(key: composeKey, split: split, atributtes: atributtes)
            
        }
        catch {
            
            return SplitConstants.CONTROL
            
        }
        
    }
    
   
}
