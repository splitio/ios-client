//
//  FeatureFlagsPayloadDecoderStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
@testable import Split

class FeatureFlagsPayloadDecoderMock: FeatureFlagsPayloadDecoder {
    
    let helper = SplitHelper()
    func decode(payload: String, compressionUtil: CompressionUtil) throws -> Split {
        return helper.createDefaultSplit(named: "dummy_split")
    }
    
}
