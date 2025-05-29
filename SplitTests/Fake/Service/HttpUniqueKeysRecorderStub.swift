//
//  HttpUniqueKeysRecorderStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 26-May-2022
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class HttpUniqueKeysRecorderStub: HttpUniqueKeysRecorder {
    var keysSent = [UniqueKey]()
    var errorOccurredCallCount = -1
    var executeCallCount = 0

    func execute(_ keys: UniqueKeys) throws {
        executeCallCount += 1
        if errorOccurredCallCount == executeCallCount {
            throw HttpError.unknown(code: -1, message: "something happend")
        }
        keysSent.append(contentsOf: keys.keys)
    }
}
