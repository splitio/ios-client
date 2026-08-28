//
//  TestUtils.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 29/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
#if SWIFT_PACKAGE
import Http
#endif

class TestUtils {
    static func buildImpressionsFromJson(content: String) throws -> [ImpressionsTest] {
        return try Json.decodeFrom(json: content, to: [ImpressionsTest].self)
    }

    static func impressionsFromHit(request: HttpDataRequest) throws -> [ImpressionsTest] {
        do {
        return try buildImpressionsFromJson(content: request.body?.stringRepresentation ?? "")
        } catch {
            print("error impressionsFromHit: \(error)")
        }
        return []
    }
}
