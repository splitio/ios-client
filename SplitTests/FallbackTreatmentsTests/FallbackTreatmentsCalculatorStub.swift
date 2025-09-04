//  Created by Martin Cardozo on 04/09/2025.
//  Copyright © 2025 Split. All rights reserved

import Foundation
@testable import Split

class DefaultFallbackTreatmentsCalculatorStub: NSObject, FallbackTreatmentsCalculator {

    private let labelPrefix = "fallback - "
    private let control = SplitConstants.control
    private let fallbacks: FallbackTreatmentsConfig? = nil

    func resolve(flagName: String, label: String?) -> FallbackTreatment {
        FallbackTreatment(treatment: control, config: nil, label: label)
    }

    private func resolveLabel(_ label: String?) -> String? {
        "\(labelPrefix)\(String(describing: label))"
    }

    private func copyWithLabel(_ fallback: FallbackTreatment, label: String?) -> FallbackTreatment {
        FallbackTreatment(treatment: fallback.treatment, config: fallback.config, label: label)
    }
}
