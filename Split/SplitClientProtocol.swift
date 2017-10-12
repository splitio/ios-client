//
//  SplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation

@objc public protocol SplitClientProtocol {
    
    func getTreatment(forSplit split: String) -> String
    
}
