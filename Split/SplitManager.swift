//
//  SplitManager.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

@objc public class SplitManager: NSObject, SplitManagerProtocol {
    
    public override init() { }
    
    public func splits() -> [SplitView] {
        return []
    }
    
    public func split(featureName: String) -> SplitView {
        return SplitView()
    }
    
    public func splitNames() -> [String] {
        return []
    }
}
