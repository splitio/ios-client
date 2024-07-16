//
//  HttpRequestManagerTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 15/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class HttpRequestManagerTests: XCTestCase {
    var reqManager: HttpRequestManager!
    var pinChecker: PinCheckerMock!
    var notificationHelper = NotificationHelperStub()

    func testWhat() {
    }

    func createManager() -> HttpRequestManager {
        pinChecker = PinCheckerMock()
        pinChecker.pinResults = results()
        return DefaultHttpRequestManager(pinChecker: pinChecker,
                                         notificationHelper: notificationHelper)
    }

    func results() -> [CredentialValidationResult] {
        return [
            .success,
            .invalidChain,
            .credentialNotPinned
        ]
    }
}

