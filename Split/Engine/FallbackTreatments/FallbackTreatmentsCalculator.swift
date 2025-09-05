//  Copyright © 2025 Split. All rights reserved

import Foundation

protocol FallbackTreatmentsCalculator {
    func resolve(flagName: String, label: String?) -> FallbackTreatment
}

class DefaultFallbackTreatmentsCalculator: NSObject, FallbackTreatmentsCalculator {

    private let labelPrefix = "fallback - "
    private let control = SplitConstants.control
    private let fallbacksConfig: FallbackTreatmentsConfig

    init(fallbacksConfig: FallbackTreatmentsConfig) {
        self.fallbacksConfig = fallbacksConfig
        super.init()
    }

    // Returns fallback for Split if exists; "control" otherwise
    func resolve(flagName: String, label: String?) -> FallbackTreatment {
        if let treatment = fallbacksConfig.byFlag[flagName] {
            return copyWithLabel(treatment, label: label)
        }

        if let factoryFallback = fallbacksConfig.global {
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
