//
//  FeatureFlagsPayloadDecoderStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
@testable import Split

class FeatureFlagsPayloadDecoderMock: DefaultTargetingRulePayloadDecoder<Split>, @unchecked Sendable {
    let helper = SplitHelper()
    override func decode(payload: String, compressionUtil: CompressionUtil) throws -> Split {
        return helper.createDefaultSplit(named: "dummy_split")
    }
}

class RuleBasedSegmentsPayloadDecoderMock: DefaultTargetingRulePayloadDecoder<RuleBasedSegment>, @unchecked Sendable {
    let helper = SplitHelper()
    override func decode(payload: String, compressionUtil: CompressionUtil) throws -> RuleBasedSegment {
        return TestingHelper.createRuleBasedSegment(name: "dummy_rbs")
    }
}
