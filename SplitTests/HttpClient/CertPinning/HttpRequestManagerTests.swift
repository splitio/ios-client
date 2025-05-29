//
//  HttpRequestManagerTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 15/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

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
            manager.urlSession?(URLSession.shared, task: task, didReceive: dummyChallenge) { disposition, _ in
                results[result] = disposition
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 5.0)

        let res2: [CredentialValidationResult] = [
            .error,
            .invalidChain,
            .credentialNotPinned,
            .spkiError,
            .invalidCredential,
            .invalidParameter,
            .unavailableServerTrust,
        ]

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

    func testNetworkConnectionLostErrorMapping() {
        let manager = DefaultHttpRequestManager(pinChecker: nil, notificationHelper: nil)
        let taskId = 12345
        let request = ErrorCapturingHttpRequestMock(identifier: taskId)

        // Create an NSError with code -1005 (network connection lost)
        let networkError = NSError(domain: NSURLErrorDomain, code: -1005, userInfo: nil)

        manager.addRequest(request)
        manager.urlSession(
            URLSession.shared,
            task: URLTaskMock(taskIdentifier: taskId),
            didCompleteWithError: networkError)

        XCTAssertNotNil(request.completedError)
        if let error = request.completedError as? HttpError {
            switch error {
            case let .clientRelated(code, internalCode):
                XCTAssertEqual(code, 400, "Error code should be 400")
                XCTAssertEqual(internalCode, -1, "Internal code should be -1")
            default:
                XCTFail("Expected clientRelated error with code 400 but got \(error)")
            }
        } else {
            XCTFail("Expected HttpError but got \(String(describing: request.completedError))")
        }
    }

    func createRequestManager() -> URLSessionTaskDelegate {
        pinChecker = PinCheckerMock()
        pinChecker.pinResults = CredentialValidationResult.allCases
        return DefaultHttpRequestManager(
            pinChecker: pinChecker,
            notificationHelper: notificationHelper)
    }
}

class URLTaskMock: URLSessionDataTask {
    private var _taskIdentifier: Int

    init(taskIdentifier: Int = 0) {
        self._taskIdentifier = taskIdentifier
        super.init()
    }

    override func resume() {}

    override var taskIdentifier: Int {
        return _taskIdentifier
    }
}

class ErrorCapturingHttpRequestMock: HttpRequestMock {
    var completedError: Error?

    override func complete(error: HttpError?) {
        completedError = error
        super.complete(error: error)
    }
}
