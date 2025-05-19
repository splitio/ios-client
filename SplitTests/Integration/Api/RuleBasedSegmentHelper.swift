//
//  RuleBasedSegmentHelper.swift
//  SplitTests
//
//  Created on 16/05/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation
@testable import Split

class RuleBasedSegmentHelper {
    
    /// Helper method to create a rule-based segment update message
    static func createRuleBasedSegmentUpdateMessage(type: String = "RULE_BASED_SEGMENT_UPDATE", changeNumber: Int = 1000, segmentData: String) -> String {
        return StreamingIntegrationHelper.ruleBasedSegmentUpdateMessage(
            timestamp: Int(Date().timeIntervalSince1970),
            changeNumber: changeNumber,
            segmentData: segmentData
        )
    }
    
    /// Helper method to create a split update message
    static func createSplitUpdateMessage(type: String = "SPLIT_UPDATE", changeNumber: Int = 1000, splitData: String) -> String {
        return StreamingIntegrationHelper.splitUpdateWithDataMessage(
            timestamp: Int(Date().timeIntervalSince1970),
            changeNumber: changeNumber,
            splitData: splitData
        )
    }
    
    /// Helper method to push a rule-based segment update message using StreamingIntegrationHelper
    static func pushRuleBasedSegmentUpdateMessage(streamingBinding: TestStreamResponseBinding?, changeNumber: Int = 1000, segmentData: String) {
        let message = StreamingIntegrationHelper.ruleBasedSegmentUpdateMessage(
            timestamp: Int(Date().timeIntervalSince1970),
            changeNumber: changeNumber,
            segmentData: segmentData
        )
        streamingBinding?.push(message: message)
    }
    
    /// Helper method to push a split update message using StreamingIntegrationHelper
    static func pushSplitUpdateMessage(streamingBinding: TestStreamResponseBinding?, changeNumber: Int = 1000, splitData: String) {
        let message = StreamingIntegrationHelper.splitUpdateWithDataMessage(
            timestamp: Int(Date().timeIntervalSince1970),
            changeNumber: changeNumber,
            splitData: splitData
        )
        streamingBinding?.push(message: message)
    }
}
