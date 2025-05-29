//
//  HttpEventsRecorderStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class HttpEventsRecorderStub: HttpEventsRecorder {
    var eventsSent = [EventDTO]()
    var errorOccurredCallCount = -1
    var executeCallCount = 0

    func execute(_ items: [EventDTO]) throws {
        executeCallCount += 1
        if errorOccurredCallCount == executeCallCount {
            throw HttpError.unknown(code: -1, message: "something happend")
        }
        eventsSent.append(contentsOf: items)
    }
}
