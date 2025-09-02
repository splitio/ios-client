//  Created by Martin Cardozo on 25/08/2025

import Foundation

/// A class that represents a fallback treatment configuration for feature flags.
/// 
/// This class is used to define fallback treatments that will be used at
/// factory level or flag level.
@objc public class FallbackTreatment: NSObject {
    
    @objc public let treatment: String
    @objc public let config: String?
    @objc public let label: String
    
    /// Initializes a new FallbackTreatment instance.
    /// - Parameters:
    ///   - treatment: The treatment String to use as fallback.
    ///   - config: Optional dynamic configuration String for the treatment.
    @objc(initWithTreatment:config:)
    public init(treatment: String, config: String? = nil) {
        self.treatment = treatment
        self.config = config
        self.label = "fallback - " // Constant alongside the other impression labels (e.g.:  "fallback - CONTROL")
    }
   
    override public var description: String {
        "{\ntreatment: \(treatment),\nconfig: \(String(describing: config)),\nlabel: \(label)\n}"
    }
}

/// A class that holds Fallback configurations.
///
/// This class can define both a global fallback treatment and specific fallback treatments
/// for individual feature flags.
@objc public final class FallbackConfig: NSObject {
    
    @objc public let global: FallbackTreatment?
    @objc public let byFlag: [String: FallbackTreatment]
    
    /// Initializes a new FallbackConfig instance.
    /// - Parameters:
    ///   - global: The global fallback treatment that will be used instead of "control".
    ///   - byFlag: A dictionary of flag names to their specific fallback treatments.
    @objc(initWithGlobal:byFlag:)
    public init(global: FallbackTreatment? = nil, byFlag: [String: FallbackTreatment] = [:]) {
        self.global = global
        self.byFlag = byFlag
    }
    
    override public var description: String {
        "{\nglobal: \(String(describing: global))\nbyFlag: \(byFlag)\n}"
    }
}

// MARK: Builder (where sanitation happens)
@objc public final class FallbackTreatmentsConfig: NSObject {
    
    @objc public let global: FallbackTreatment?
    @objc public let byFlag: [String: FallbackTreatment]
    
    private init(global: FallbackTreatment? = nil, byFlag: [String: FallbackTreatment] = [:]) {
        self.global = global
        self.byFlag = byFlag
     }
    
    @objc public static func builder() -> Builder {
        Builder()
    }
    
    @objc public final class Builder: NSObject {
        
        private var global: FallbackTreatment? = nil
        private var byFlag: [String: FallbackTreatment] = [:]
        
        @objc public func build() -> FallbackTreatmentsConfig {
             FallbackTreatmentsConfig(global: global, byFlag: byFlag)
        }
        
        // MARK: Global
        @objc(global:)
        public func global(_ treatment: FallbackTreatment) -> Builder {
            guard let sanitizedGlobal = FallbackSanitizer.sanitize(treatment: treatment) else { return self }

            if global != nil {
                Logger.w("Fallback treatments - You had previously set a global fallback. The new value will replace it")
            }

            global = sanitizedGlobal
            return self
        }
        
        // MARK: By Flag
        @objc(byFlag:)
        public func byFlag(_ byFlagFallbacks: [String: FallbackTreatment]) -> Builder {
            
            // Warn if you're overriding an already configured flag
            for key in byFlagFallbacks.keys where byFlag.keys.contains(key) {
                Logger.w("Duplicate fallback for flag '\(key)'. Overriding existing value.")
            }
            
            // Merge
            var merged = byFlag
            for (k, v) in byFlagFallbacks {
                merged[k] = v
            }
            
            // Sanitize final map
            byFlag = FallbackSanitizer.sanitize(byFlagFallbacks: merged)
            return self
        }
        
        // MARK: Convenience String only methods
        @objc(globalWithString:) public func global(_ treatment: String) -> Builder {
            global(FallbackTreatment(treatment: treatment))
        }
        
        @objc(byFlagWithString:) public func byFlag(_ byFlagFallbacks: [String: String]) -> Builder {
            let mapped = byFlagFallbacks.mapValues { FallbackTreatment(treatment: $0) }
            return byFlag(mapped)
        }
    }
}
