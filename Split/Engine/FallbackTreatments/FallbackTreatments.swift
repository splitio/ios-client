//  Created by Martin Cardozo on 25/08/2025

public struct FallbackTreatment: Equatable, Hashable {
    
    let treatment: String
    let config: String?
    let label: String
    
    init(_ treatment: String, config: String? = nil) {
        self.treatment = treatment
        self.config = config
        self.label = "fallback - " // Constant alongisde the other impression labels (e.g.:  "fallback treatment - CONTROL" )
    }
}

public struct FallbackConfig: Equatable, Hashable {
    
    let global: FallbackTreatment? // Default treatment for all
    let byFlag: [String: FallbackTreatment] // Fallback treatment per flag
    
    init(global: FallbackTreatment? = nil, byFlag: [String: FallbackTreatment] = [:]) {
        self.global = global
        self.byFlag = byFlag
    }
}
