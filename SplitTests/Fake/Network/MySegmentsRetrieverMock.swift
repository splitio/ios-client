//
//  MySegmentsRetrieverMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 05/08/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split

struct SegmentsRetrieverMock: SegmentsRetriever {
    var resource: Resource
    func retrieve(userKey: String, headers: [String: String]?) -> DataResult<SegmentChange>? {
        return nil
    }
}
