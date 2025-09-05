//  Copyright © 2025 Split. All rights reserved

import Foundation

protocol FallbackTreatmentsCalculator {
    func resolve(flagName: String, label: String?) -> FallbackTreatment
}

@objc public class DefaultFallbackTreatmentsCalculator: NSObject, FallbackTreatmentsCalculator {

    private let labelPrefix = "fallback - "
    private let control = SplitConstants.control
    private let fallbacks: FallbackTreatmentsConfig

    @objc public init(fallbacksConfig: FallbackTreatmentsConfig) {
        fallbacks = fallbacksConfig
        super.init()
    }

    // Returns fallback for Split if exists; "control" otherwise
    @objc(resolve:label:)
    public func resolve(flagName: String, label: String?) -> FallbackTreatment {
        
        if let flagTreatment = fallbacks.byFlag[flagName] {
            return copyWithLabel(flagTreatment, label: resolveLabel(label))
        }

        if let clientFallback = fallbacks.global {
            return copyWithLabel(clientFallback, label: resolveLabel(label))
        }

        return FallbackTreatment(treatment: control, config: nil, label: label)
    }

    private func resolveLabel(_ label: String?) -> String? {
        guard let lbl = label else { return nil }
        return "\(labelPrefix)\(lbl)"
    }

    private func copyWithLabel(_ fallback: FallbackTreatment, label: String?) -> FallbackTreatment {
        FallbackTreatment(treatment: fallback.treatment, config: fallback.config, label: label)
    }
}
