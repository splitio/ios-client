//
//  SplitFactoryProtocol.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

@objc public protocol SplitFactoryProtocol {
    
    func splitClient() -> SplitClientProtocol
    
    func splitManager() -> SplitManagerProtocol
    
}
