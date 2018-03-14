//
//  SplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation

public protocol SplitClientProtocol {
    
    func getTreatment(_ split: String, _ attributes:[String:Any]?) -> String

}
