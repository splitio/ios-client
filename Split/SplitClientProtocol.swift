//
//  SplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation

public protocol SplitClientProtocol {
    
    func getTreatment(key:String, split: String) -> String
    
    func getTreatment(key:String, split: String, atributtes:[String:Any]?) -> String
    
    func getTreatment(key:Key, split: String, atributtes:[String:Any]?) -> String


}
