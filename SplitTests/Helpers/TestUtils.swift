//
//  TestUtils.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 29/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class TestUtils {
    static func buildImpressionsFromJson(content: String) throws -> [ImpressionsTest] {
        return try Json.encodeFrom(json: content, to: [ImpressionsTest].self)
    }

    static func impressionsFromHit(request: ClientRequest) throws -> [ImpressionsTest] {
        return try buildImpressionsFromJson(content: request.data!)
    }
}
