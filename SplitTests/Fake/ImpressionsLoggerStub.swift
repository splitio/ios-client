//
//  ImpressionsLoggerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 25/01/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split

class ImpressionsLoggerStub: ImpressionLogger {
    var impressions = [String: KeyImpression]()
    var impressionsPushedCount = 0
    func pushImpression(impression: DecoratedImpression) {
        let impression = impression.impression
        guard let splitName = impression.featureName else {
            return
        }
        impressions[splitName] = impression
        impressionsPushedCount += 1
    }
}
