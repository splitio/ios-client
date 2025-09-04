//  Copyright © 2025 Split. All rights reserved

import Foundation

protocol FallbackTreatmentsCalculator {
    func resolve(flagName: String, label: String?) -> FallbackTreatment
}

@objc public class DefaultFallbackTreatmentsCalculator: NSObject, FallbackTreatmentsCalculator {

    private let labelPrefix = "fallback - "
    private let control = SplitConstants.control
    private let byFactoryFallbacks: FallbackTreatmentsConfig

    @objc public init(factory: FallbackTreatmentsConfig) {
        self.byFactoryFallbacks = factory
        super.init()
    }

    // Returns fallback for Split if exists; "control" otherwise
    @objc(resolve:label:)
    public func resolve(flagName: String, label: String?) -> FallbackTreatment {
        if let treatment = byFactoryFallbacks.byFlag[flagName] {
            return copyWithLabel(treatment, label: label)
        }

        if let factoryFallback = byFactoryFallbacks.global {
            return copyWithLabel(factoryFallback, label: label)
        }

        return FallbackTreatment(treatment: control, config: nil, label: resolveLabel(label))
    }

    private func resolveLabel(_ label: String?) -> String? {
        guard let lbl = label else { return nil }
        return "\(labelPrefix)\(lbl)"
    }

    private func copyWithLabel(_ fallback: FallbackTreatment, label: String?) -> FallbackTreatment {
        FallbackTreatment(treatment: fallback.treatment, config: fallback.config, label: resolveLabel(label))
    }
}
