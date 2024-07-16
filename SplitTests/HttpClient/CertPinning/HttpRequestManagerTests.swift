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
    let securityHelper = SecurityHelper()
    let hostName = "www.test.com"
    let certName = "rsa_4096_cert.pem"
    var dummyChallenge: URLAuthenticationChallenge!

    override func setUp() {
        dummyChallenge = securityHelper.createAuthChallenge(host: hostName, certName: certName)
    }

    func testPinnedCredentialValidation() {
        let exp = XCTestExpectation()
        let request = URLRequest(url: URL(string: hostName)!)
        let task = URLSession.shared.dataTask(with: request)
        let manager = createRequestManager()
        var notifications = [String]()
        var results = [CredentialValidationResult: URLSession.AuthChallengeDisposition]()

        notificationHelper.addObserver(for: .pinnedCredentialValidationFail) { info in
            guard let info = info as? String else {
                XCTFail()
                return
            }
            notifications.append(info)
        }
        
        for result in CredentialValidationResult.allCases {
            manager.urlSession?(URLSession.shared, task: task, didReceive: dummyChallenge) {disposition,_ in
                results[result] = disposition
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 5.0)

        let res2: [CredentialValidationResult] = [.error, .invalidChain, .credentialNotPinned, .spkiError,
                                                  .invalidCredential, .invalidParameter, .unavailableServerTrust]

        let res3: [CredentialValidationResult] = [.noServerTrustMethod, .noPinsForDomain]

        XCTAssertEqual(notifications.count, 7)
        XCTAssertEqual(results.count, 10)
        XCTAssertEqual(results[.success], .useCredential)
        for res in res2 {
            XCTAssertEqual(results[res], .cancelAuthenticationChallenge)
        }

        for res in res3 {
            XCTAssertEqual(results[res], .performDefaultHandling)
        }

        XCTAssertEqual(notifications[0], hostName)
    }

    func createRequestManager() -> URLSessionTaskDelegate {
        pinChecker = PinCheckerMock()
        pinChecker.pinResults = CredentialValidationResult.allCases
        return DefaultHttpRequestManager(pinChecker: pinChecker,
                                         notificationHelper: notificationHelper)
    }
}

class URLTaskMock: URLSessionDataTask {
    override func resume() {
    }
}
