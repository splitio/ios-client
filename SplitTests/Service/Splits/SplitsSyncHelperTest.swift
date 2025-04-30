//  SplitsSyncHelperTest.swift
//  Split
// 
//  Created by Martin Cardozo on 29/04/2025.
//  Copyright © 2025 Split. All rights reserved.

import Foundation

import XCTest
@testable import Split

class SplitsSyncHelpersTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSync() throws {
        
        // Storage
        let persistentStorage = PersistentSplitsStorageStub()
        let flagSetsCache     = FlagSetsCacheMock()
        let splitsStorage     = DefaultSplitsStorage(persistentSplitsStorage: persistentStorage, flagSetsCache: flagSetsCache)
        //var storage = new Mock<SplitStorage>();
        // Client
        let httpClient       = DefaultHttpClient(session: DefaultHttpSession(urlSession: URLSession()))
        let serviceEndpoints = ServiceEndpoints.Builder().build()
        let restClient       = DefaultRestClient(httpClient: httpClient,
                                                 endpointFactory: EndpointFactory(serviceEndpoints: serviceEndpoints,
                                                                                  apiKey: CommonValues.apiKey,
                                                                                  splitsQueryString: ""))
        
        let splitFetcher = DefaultHttpSplitFetcher(restClient: restClient, syncHelper: DefaultSyncHelper(telemetryProducer: TelemetryStorageStub()))

        let sut = SplitsSyncHelper(
            splitFetcher: splitFetcher,
            splitsStorage: splitsStorage,
            splitChangeProcessor: SplitChangeProcessorStub(),
            splitConfig: TestingHelper.basicStreamingConfig()
        )
        
        let result = try sut.sync(since: 1200, rbSince: 1400, till: 2000, clearBeforeUpdate: false)

        // Add asserts here if needed
    }
    
}
