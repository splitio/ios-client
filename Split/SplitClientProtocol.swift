//
//  SplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation

public protocol SplitClientProtocol {
    
    func getTreatment(_ split: String, attributes:[String:Any]?) -> String

}

public extension SplitClientProtocol {
    
    func getTreatment(_ split: String, attributes:[String:Any]? = nil) -> String {
        return getTreatment(split, attributes: attributes)
    }
    
}
