//
//  LocalhostSplitsParser.swift
//  Split
//
//  Created by Javier L. Avrudsky on 31/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
/**
 Data structure to hold parsed feature flags and its corresponding treatment
 */
typealias LocalhostSplits = [String: Split]

/**
 Interface to implement by classes intended to parse
 feature flags loaded for localhost feature
 */
protocol LocalhostSplitsParser {
    func parseContent(_ content: String) -> LocalhostSplits
}
