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
    func parseContent(_ content: String) -> LocalhostSplits?
}

enum LocalhostParserProvider {
    static func parser(for type: String) -> LocalhostSplitsParser {
        if type == "yaml" || type == "yml" {
            return YamlLocalhostSplitsParser()
        }
        Logger.w("""
        Localhost mode: .split mocks will be deprecated soon in favor of YAML files,
        which provide more targeting power. Take a look in our documentation.
        """)
        return SpaceDelimitedLocalhostSplitsParser()
    }

    static func parser(for type: LocalhostFile) -> LocalhostSplitsParser {
        switch type {
        case .splits:
            return SpaceDelimitedLocalhostSplitsParser()
        case .yaml:
            return YamlLocalhostSplitsParser()
        }
    }
}
