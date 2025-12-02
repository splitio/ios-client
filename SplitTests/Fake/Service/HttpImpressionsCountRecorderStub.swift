//
//  HttpImpressionsCountRecorderStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 23-Jun-2021
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split

class HttpImpressionsCountRecorderStub: HttpImpressionsCountRecorder, @unchecked Sendable {

    var countsSent = [ImpressionsCountPerFeature]()
    var errorOccurredCallCount = -1
    var executeCallCount = 0

    func execute(_ counts: ImpressionsCount) throws {
        executeCallCount+=1
        if errorOccurredCallCount == executeCallCount {
            throw HttpError.unknown(code: -1, message: "something happend")
        }
        countsSent.append(contentsOf: counts.perFeature)
    }
}
