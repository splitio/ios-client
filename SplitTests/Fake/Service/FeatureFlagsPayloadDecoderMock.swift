//
//  FeatureFlagsPayloadDecoderStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
@testable import Split

class FeatureFlagsPayloadDecoderMock: DefaultTargetingRulePayloadDecoder<Split> {
    let helper = SplitHelper()
    override func decode(payload: String, compressionUtil: CompressionUtil) throws -> Split {
        return helper.createDefaultSplit(named: "dummy_split")
    }
}

class RuleBasedSegmentsPayloadDecoderMock: DefaultTargetingRulePayloadDecoder<RuleBasedSegment> {
    let helper = SplitHelper()
    override func decode(payload: String, compressionUtil: CompressionUtil) throws -> RuleBasedSegment {
        let rbs = RuleBasedSegment()
        rbs.name = "dummy_rbs"
        rbs.isParsed = true
        rbs.trafficTypeName = "custom"
        rbs.status = .active
        rbs.json = ""
        return rbs
    }
}
