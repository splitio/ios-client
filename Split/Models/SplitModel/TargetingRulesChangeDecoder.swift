//
//  TargetingRulesChangeDecoder.swift
//  Split
//
//  Created on 12/05/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation

class TargetingRulesChangeDecoder {
    
    /// Decodes a JSON response into a TargetingRulesChange object.
    /// This decoder can handle both the new TargetingRulesChange format and the legacy SplitChange format.
    /// If the legacy format is detected, it will create a TargetingRulesChange with the SplitChange data
    /// and an empty RuleBasedSegmentChange.
    ///
    /// - Parameter data: The JSON data to decode
    /// - Returns: A TargetingRulesChange object
    /// - Throws: Decoding errors if the JSON cannot be parsed
    static func decode(from data: Data) throws -> TargetingRulesChange {
        // First try to decode as TargetingRulesChange
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(TargetingRulesChange.self, from: data)
        } catch {
            // If that fails, try to handle the legacy format with full keys (splits, since, till)
            do {
                let splitChangeJson = try JSONSerialization.jsonObject(with: data, options: [])

                if let jsonDict = splitChangeJson as? [String: Any],
                   let splitsArray = jsonDict["splits"],
                   let since = jsonDict["since"] as? Int64,
                   let till = jsonDict["till"] as? Int64 {
                    
                    // Convert to the format with short keys that SplitChange expects
                    var newJsonDict = [String: Any]()
                    newJsonDict["d"] = splitsArray
                    newJsonDict["s"] = since
                    newJsonDict["t"] = till
                    
                    let newJsonData = try JSONSerialization.data(withJSONObject: newJsonDict, options: [])
                    let decoder = JSONDecoder()
                    let splitChange = try decoder.decode(SplitChange.self, from: newJsonData)
                    
                    // Create a TargetingRulesChange with the SplitChange data and an empty RuleBasedSegmentChange
                    return TargetingRulesChange(
                        featureFlags: splitChange,
                        ruleBasedSegments: RuleBasedSegmentChange.empty()
                    )
                }
                
                // If we get here, no format matched
                throw error
            } catch {
                // If all decodings fail, throw the original error
                throw error
            }
        }
    }
}
