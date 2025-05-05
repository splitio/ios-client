//
//  HttpTaskMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 25/06/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class HttpTaskMock: HttpTask {
    var identifier: Int = -1

    init(identifier: Int) {
        self.identifier = identifier
    }

    func cancel() {}
}
