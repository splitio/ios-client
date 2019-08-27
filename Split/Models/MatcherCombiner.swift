//
//  MatcherCombiner.swift
//  Split
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc enum MatcherCombiner: Int, Codable {
    case and

    public typealias RawValue = Int

    enum CodingKeys: String, CodingKey {
        case intValue
    }

    init(from decoder: Decoder) throws {
        self = MatcherCombiner.enumFromString(string: "and")!
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("and")
    }

    static func enumFromString(string: String) -> MatcherCombiner? {
        switch string.lowercased() {
        case "and":
            return .and

        default:
            return nil
        }
    }

    func combineAndResults(partialResults: [Bool]) -> Bool {
        return !partialResults.contains(false)
    }
}
