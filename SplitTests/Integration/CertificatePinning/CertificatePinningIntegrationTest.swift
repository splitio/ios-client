//
//  CertificatePinningIntegrationTest.swift
//  SplitTests
//

import XCTest
@testable import Split

class CertificatePinningIntegrationTest: XCTestCase {
    
    var factory: SplitFactory?
    
    override func tearDown() {
        HttpSessionConfig.default.pinChecker = nil
        HttpSessionConfig.default.notificationHelper = nil
        super.tearDown()
    }

    func testFactoryWiringOfStatusHandler() {
        let expectation = self.expectation(description: "Status handler called")
        let testHost = "www.test.com"
        let testReason = "TestReason"
        let testStatus = CertificatePinningStatus.success
        
        let pinningConfigBuilder = CertificatePinningConfig.builder()
        pinningConfigBuilder.addPin(host: "www.google.com", keyHash: "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
        
        pinningConfigBuilder.statusHandler { host, status, reason in
            XCTAssertEqual(host, testHost)
            XCTAssertEqual(status, testStatus)
            XCTAssertEqual(reason, testReason)
            expectation.fulfill()
        }
        
        guard let pinningConfig = try? pinningConfigBuilder.build() else {
            XCTFail("Failed to build pinning config")
            return
        }

        let builder = IntegrationHelper().simplestFactoryWithDummyKeys()
        let splitConfig = SplitClientConfig()
        splitConfig.certificatePinningConfig = pinningConfig
        _ = builder.setConfig(splitConfig)

        factory = builder.build()
        XCTAssertNotNil(factory)
        XCTAssertNotNil(HttpSessionConfig.default.pinChecker)
        XCTAssertNotNil(HttpSessionConfig.default.notificationHelper)
        
        // Simulate a notification to prove the listener is active
        guard let notificationHelper = HttpSessionConfig.default.notificationHelper else {
            XCTFail("Notification helper is nil")
            return
        }
        let statusObj = CertificatePinningCompleteStatus(host: testHost, status: testStatus, reason: testReason)
        notificationHelper.post(notification: .pinnedCredentialStatus, info: statusObj)
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testFactoryWiringOfBothHandlers() {
        let statusExpectation = self.expectation(description: "Status handler called")
        let failureExpectation = self.expectation(description: "Failure handler called")
        let testHost = "www.test.com"
        
        let pinningConfigBuilder = CertificatePinningConfig.builder()
        pinningConfigBuilder.addPin(host: "www.google.com", keyHash: "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
        
        pinningConfigBuilder.statusHandler { _, status, _ in
            if status == .failed {
                statusExpectation.fulfill()
            }
        }
        
        pinningConfigBuilder.failureHandler { host in
            XCTAssertEqual(host, testHost)
            failureExpectation.fulfill()
        }
        
        guard let pinningConfig = try? pinningConfigBuilder.build() else {
            XCTFail("Failed to build pinning config")
            return
        }
        
        let builder = IntegrationHelper().simplestFactoryWithDummyKeys()
        let splitConfig = SplitClientConfig()
        splitConfig.certificatePinningConfig = pinningConfig
        _ = builder.setConfig(splitConfig)
        
        factory = builder.build()
        XCTAssertNotNil(factory)
        
        guard let notificationHelper = HttpSessionConfig.default.notificationHelper else {
            XCTFail("Notification helper is nil")
            return
        }
        
        // Post failure notification (triggers failureHandler)
        notificationHelper.post(notification: .pinnedCredentialValidationFail, info: testHost as AnyObject)

        // Post status notification (triggers statusHandler)
        let statusObj = CertificatePinningCompleteStatus(host: testHost, status: .failed, reason: "Error")
        notificationHelper.post(notification: .pinnedCredentialStatus, info: statusObj)
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
