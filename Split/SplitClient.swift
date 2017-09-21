//
//  SplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation

@objc public protocol SplitClient {
    
    func getTreatment(forSplit split: String) -> String
    
}
