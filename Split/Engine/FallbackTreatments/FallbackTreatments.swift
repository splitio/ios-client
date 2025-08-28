//  Created by Martin Cardozo on 25/08/2025

import Foundation

@objc public class FallbackTreatment: NSObject {
    
    @objc public let treatment: String
    @objc public let config: String?
    @objc public let label: String
    
    @objc public init(_ treatment: String, config: String? = nil) {
        self.treatment = treatment
        self.config = config
        self.label = "fallback - " // Constant alongisde the other impression labels (e.g.:  "fallback - CONTROL" )
    }
    
    override public var description: String {
        return "{\treatment: \(treatment),\nconfig: \(String(describing: config)),\nlabel: \(label)\n}"
    }
}

@objc public class FallbackConfig: NSObject {
     
    @objc public let global: FallbackTreatment? // Default treatment for all
    @objc public let byFlag: [String: FallbackTreatment] // Fallback treatment per flag
    
    @objc public init(global: FallbackTreatment? = nil, byFlag: [String: FallbackTreatment] = [:]) {
        self.global = global
        self.byFlag = byFlag
    }
    
    override public var description: String {
        return "{\nglobal: \(String(describing: global))\nbyFlag: \(byFlag)\n}"
    }
}
