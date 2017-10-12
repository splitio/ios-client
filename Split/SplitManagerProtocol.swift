//
//  SplitManagerProtocol.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

@objc public protocol SplitManagerProtocol {
    
    func splits() -> [SplitView]
    
    func split(featureName: String) -> SplitView
    
    func splitNames() -> [String]

}
