//
//  IntegrationHelper.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 01/10/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

class IntegrationHelper {
    static func buildImpressionKey(impression: Impression) -> String {
        return buildImpressionKey(key: impression.keyName!, splitName: impression.feature!, treatment: impression.treatment!)
    }

    static func buildImpressionKey(key: String, splitName: String, treatment: String) -> String {
        return "(\(key)_\(splitName)_\(treatment)"
    }
}
