//
//  SplitChangeFetcherTests.swift
//  Split
//
//  Created by Brian Sztamfater on 3/10/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class SplitChangeFetcherTests: XCTestCase {

    var splitChangeFetcher: SplitChangeFetcher!
    var splitCache: SplitCache!

    override func setUp() {
        splitCache = SplitCache(fileStorage: FileStorageStub(), notificationHelper: DefaultNotificationHelper.instance)
        let endpointFactory = EndpointFactory(serviceEndpoints: IntegrationHelper.mockServiceEndpoint,
                                              apiKey: IntegrationHelper.dummyApiKey,
                                              userKey: IntegrationHelper.dummyUserKey,
                                              splitsQueryString: "")
        let restClient = DefaultRestClient(endpointFactory: endpointFactory)
        splitChangeFetcher = HttpSplitChangeFetcher(restClient: restClient, splitCache: splitCache, defaultQueryString: "")
    }

    override func tearDown() {
    }

    func testFetchCount() {

        let restClient: RestClientSplitChanges = RestClientStub()
        let restClientTest: RestClientTest = restClient as! RestClientTest
        restClientTest.update(change: getChanges(fileName: "splitchanges_1"))

        splitChangeFetcher = HttpSplitChangeFetcher(restClient: restClient, splitCache: splitCache, defaultQueryString: "")
        var response: SplitChange? = nil
        do {
            response = try splitChangeFetcher.fetch(since: -1)
        } catch {
        }
        XCTAssertTrue(response != nil, "Response should not be nil")
        if let response = response {
            XCTAssertTrue(response.splits!.count > 0, "Split count should be greater than 0")
        }
    }

    func testChangeFetch() {
        let restClient: RestClientSplitChanges = RestClientStub()
        let restClientTest: RestClientTest = restClient as! RestClientTest
        restClientTest.update(change: getChanges(fileName: "splitchanges_2"))

        splitChangeFetcher = HttpSplitChangeFetcher(restClient: restClient, splitCache: splitCache, defaultQueryString: "")
        var response: SplitChange? = nil
        do {
            response = try splitChangeFetcher.fetch(since: -1)
        } catch {
        }

        XCTAssertTrue(response != nil, "Response should not be nil")
        if let response = response {
            XCTAssertEqual(response.splits!.count, 1, "Splits count should be 1")
            let split = response.splits![0];
            XCTAssertEqual(split.name, "FACUNDO_TEST", "Split name value")
            XCTAssertFalse(split.killed!, "Split killed value should be false")
            XCTAssertEqual(split.status, .active, "Split status should be 'Active'")
            XCTAssertEqual(split.trafficTypeName, "account", "Split traffict type should be account")
            XCTAssertEqual(split.defaultTreatment, "off", "Default treatment value")
            XCTAssertNotNil(split.conditions, "Conditions should not be nil")
            XCTAssertNotNil(split.configurations, "Configurations should not be nil")
            XCTAssertNotNil(split.configurations?["on"])
            XCTAssertNotNil(split.configurations?["off"])
            XCTAssertEqual(response.since, -1, "Since should be -1")
            XCTAssertEqual(response.till, 1506703262916, "Check till value")
            XCTAssertNil(split.algo, "Algo should be nil")
        }
    }

    func testSplitsTillAndSince() {
        let restClient: RestClientSplitChanges = RestClientStub()
        let restClientTest: RestClientTest = restClient as! RestClientTest
        restClientTest.update(change: getChanges(fileName: "splitchanges_3"))

        splitChangeFetcher = HttpSplitChangeFetcher(restClient: restClient, splitCache: splitCache, defaultQueryString: "")
        var response: SplitChange?
        var errorHasOccurred = false
        do {
            response = try splitChangeFetcher.fetch(since: -1)
        } catch {
            errorHasOccurred = true
        }
        XCTAssertTrue(errorHasOccurred, "An exception should be raised")
        XCTAssertTrue(response == nil, "Response should be nil")
    }

    func testSplitsQueryStringChanged() {
        // When querystring changes
        // Old splits has to be removed and querystring updated

        let restClient: RestClientSplitChanges = RestClientStub()
        let restClientTest: RestClientTest = restClient as! RestClientTest

        let newSplit = Split()
        newSplit.name = "new"
        let c = SplitChange()
        c.splits = [newSplit]
        c.since = 300
        c.till = 400
        restClientTest.update(change: c)
        let split = Split()
        split.name = "toberemoved"
        let splitCache = SplitCacheStub(splits: [split], changeNumber: 100, queryString: "q=2")

        splitChangeFetcher = HttpSplitChangeFetcher(restClient: restClient, splitCache: splitCache, defaultQueryString: "q=1")
        do {
            _ = try splitChangeFetcher.fetch(since: -1)
        } catch {
        }
        XCTAssertEqual(1, splitCache.getSplits().values.filter { $0.name == "new" }.count)
        XCTAssertEqual(0, splitCache.getSplits().values.filter { $0.name == "toberemoved" }.count)
        XCTAssertEqual(1, splitCache.getSplits().count)
        XCTAssertEqual("q=1", splitCache.getQueryString())
    }


    func testSplitsQueryStringHasNotChanged() {
        // When querystring doesn't change
        // Old splits has to be maintained and querystring don't change
        let restClient: RestClientSplitChanges = RestClientStub()
        let restClientTest: RestClientTest = restClient as! RestClientTest

        let newSplit = Split()
        newSplit.name = "new"
        let c = SplitChange()
        c.splits = [newSplit]
        c.since = 300
        c.till = 400
        restClientTest.update(change: c)
        let split = Split()
        split.name = "tomaintain"
        let splitCache = SplitCacheStub(splits: [split], changeNumber: 100, queryString: "q=1")

        splitChangeFetcher = HttpSplitChangeFetcher(restClient: restClient, splitCache: splitCache, defaultQueryString: "q=1")
        do {
            _ = try splitChangeFetcher.fetch(since: -1)
        } catch {
        }
        XCTAssertEqual(1, splitCache.getSplits().values.filter { $0.name == "new" }.count)
        XCTAssertEqual(1, splitCache.getSplits().values.filter { $0.name == "tomaintain" }.count)
        XCTAssertEqual(2, splitCache.getSplits().count)
        XCTAssertEqual("q=1", splitCache.getQueryString())
    }

    func getChanges(fileName: String) -> SplitChange? {
        var change: SplitChange?
        if let content = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json") {
            change = try? Json.encodeFrom(json: content, to: SplitChange.self)
        }
        return change
    }
}
