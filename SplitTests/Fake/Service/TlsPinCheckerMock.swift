//
//  TlsPinCheckerMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 15/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split

class PinCheckerMock: TlsPinChecker {
    var pinResults = [CredentialValidationResult]()
    private var respIndex = -1

    func resetIndex() {
        respIndex = -1
    }

    func check(credential: AnyObject) -> CredentialValidationResult {
        respIndex += 1
        return pinResults[respIndex]
    }
}
