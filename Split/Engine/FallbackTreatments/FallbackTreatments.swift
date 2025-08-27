//  Created by Martin Cardozo on 25/08/2025

import Foundation

@objc public class FallbackTreatment: NSObject {
    
    let treatment: String
    let config: String?
    let label: String
    
    init(_ treatment: String, config: String? = nil) {
        self.treatment = treatment
        self.config = config
        self.label = "fallback - " // Constant alongisde the other impression labels (e.g.:  "fallback treatment - CONTROL" )
    }
}

@objc public class FallbackConfig: NSObject {
    
    let global: FallbackTreatment? // Default treatment for all
    let byFlag: [String: FallbackTreatment] // Fallback treatment per flag
    
    init(global: FallbackTreatment? = nil, byFlag: [String: FallbackTreatment] = [:]) {
        self.global = global
        self.byFlag = byFlag
    }
}
