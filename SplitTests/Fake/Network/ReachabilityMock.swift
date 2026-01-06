//
//  ReachabilityMock.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 14/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

@testable import Split

class ReachabilityMock: HostReachabilityChecker, @unchecked Sendable {
    func isReachable(path url: String) -> Bool {
        return true
    }
}
