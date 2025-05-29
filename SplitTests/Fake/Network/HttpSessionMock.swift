//
//  HttpSessionMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 25/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class HttpSessionMock: HttpSession {
    func finalize() {}

    private(set) var dataTaskCallCount: Int = 0
    func startTask(with request: HttpRequest) -> HttpTask? {
        dataTaskCallCount += 1
        return HttpTaskMock(identifier: 100)
    }
}
