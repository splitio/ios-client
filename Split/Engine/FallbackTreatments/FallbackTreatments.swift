//  Created by Martin Cardozo on 25/08/2025

import Foundation

/// A class that represents a fallback treatment configuration for feature flags.
/// 
/// This class is used to define fallback treatments that will be used at
/// factory level or flag level.
@objc public class FallbackTreatment: NSObject {
    
    @objc public let treatment: String
    @objc public let config: String?
    @objc public let label: String?
    
    /// Initializes a new FallbackTreatment instance.
    /// - Parameters:
    ///   - treatment: The treatment String to use as fallback.
    ///   - config: Optional dynamic String configuration for the treatment.
    @objc(initWithTreatment:config:)
    public init(treatment: String, config: String? = nil) {
        self.treatment = treatment
        self.config = config
        self.label = "fallback - " // Constant alongside the other impression labels (e.g.:  "fallback - CONTROL")
    }
    
    internal init(treatment: String, config: String? = nil, label: String? = nil) {
      self.treatment = treatment
      self.config = config
      self.label = label
    }
    
    override public var description: String {
        "{\ntreatment: \(treatment),\nconfig: \(String(describing: config)),\nlabel: \(String(describing: label))\n}"
    }
}
