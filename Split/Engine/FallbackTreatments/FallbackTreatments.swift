//  Created by Martin Cardozo on 25/08/2025

// MARK: 1. Main Data Structure
public struct FallbackTreatment: Equatable, Hashable {
    
    let treatment: String
    let config: String?
    let label: String
    
    init(_ treatment: String, config: String? = nil) {
        self.treatment = treatment
        self.config = config
        self.label = "fallback - " // Constant alongisde the other impression labels (e.g.:  "fallback - CONTROL" )
    }
}

// MARK: 2. Data Structures Package
public struct FallbackConfig: Equatable, Hashable {
    
    let global: FallbackTreatment? // Default treatment for all
    let byFlag: [String: FallbackTreatment] // Fallback treatment per flag
    
    init(global: FallbackTreatment? = nil, byFlag: [String: FallbackTreatment] = [:]) {
        self.global = global
        self.byFlag = byFlag
    }
}

// MARK: 3. Builder (where sanitation happens)
public struct FallbackTreatmentsConfig: Equatable, Hashable {
    
    let configByFactory: FallbackConfig?
    
    static func builder() -> Builder { Builder() }
    
    struct Builder {
        
        private var configByFactory: FallbackConfig?
        
        func byFactory(_ config: FallbackConfig) -> Builder {
            var builder = self
            builder.configByFactory = FallbackSanitizer.sanitize(config)
            return builder
        }
        
        func build() -> FallbackTreatmentsConfig {
            FallbackTreatmentsConfig(configByFactory: configByFactory)
        }
    }
}
