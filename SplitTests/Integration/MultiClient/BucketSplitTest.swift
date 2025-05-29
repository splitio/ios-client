//
//  BucketSplitTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 28-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class BucketSplitTest: XCTestCase {
    let splitName = "bucket_test"
    var streamingBinding: TestStreamResponseBinding?
    let userKey = "littleSpoon"
    let trafficType = "client"
    let bucketsKeys = [
        "2643632B-D2D7-4DDF-89EA-A2563CFE317F": "V1",
        "62FAA071-E87B-4FA7-A059-CD10C8BD78C6": "V10",
        "596DBDCF-0FF3-4F07-A5F4-A2386EAD540B": "V20",
        "A4232DB6-B609-49C5-84A3-55BB80F70122": "V30",
        "E4457B93-7D9C-4E1A-B363-492FAC589077": "V40",
        "206AEA7F-0392-4159-8A64-1DAE8B20BA6D": "V50",
        "393899EB-AD1D-4943-8136-2481DE7A0875": "V60",
        "7B7AD9AC-21C7-46C0-B49B-A19BBE726409": "V70",
        "9975F10D-044A-48C8-8443-2816B92852DC": "V80",
        "DC8B43D2-5D06-48D3-B1FD-FEDF1A6DC2F1": "V90",
        "0E7C9914-7268-452A-B855-DF06542C1FE7": "V100",
    ]

    let dbqueue = DispatchQueue(label: "testqueue", target: DispatchQueue.test)

    var cachedSplit: Split!
    var clients = [Key: SplitClient]()
    var readyExps = [Key: XCTestExpectation]()
    var factory: SplitFactory!

    override func setUp() {
        setupFactory()
    }

    func testMultiClientBuckets() {
        for (bkey, _) in bucketsKeys {
            let key = Key(matchingKey: userKey, bucketingKey: bkey)
            readyExps[key] = XCTestExpectation(description: "key: \(bkey)")
            clients[key] = factory.client(key: key)
            clients[key]?.on(event: SplitEvent.sdkReady) {
                print("READY FOR: \(key.bucketingKey!)")
                self.readyExps[key]?.fulfill()
            }
        }
        wait(for: readyExps.values.map { $0 }, timeout: 10)

        var results = [String: String]()
        doInAllClients { key, client in
            results[key.bucketingKey!] = client.getTreatment(splitName)
        }

        doInAllClients { key, _ in
            XCTAssertEqual(bucketsKeys[key.bucketingKey!]!, results[key.bucketingKey!]!)
        }

        for client in clients.values {
            client.destroy()
        }
    }

    private func getChanges() -> Data {
        let changeNumber = 5000
        var content = FileHelper.readDataFromFile(
            sourceClass: IntegrationHelper(),
            name: "bucket_split_test",
            type: "json")!
        content = content.replacingOccurrences(of: "<FIELD_SINCE>", with: "\(changeNumber)")
        content = content.replacingOccurrences(of: "<FIELD_TILL>", with: "\(changeNumber)")
        return Data(content.utf8)
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                return TestDispatcherResponse(code: 200, data: self.getChanges())
            }

            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            return TestDispatcherResponse(code: 200)
        }
    }

    private func doInAllClients(action: (Key, SplitClient) -> Void) {
        for (key, client) in clients {
            action(key, client)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            DispatchQueue.test.asyncAfter(deadline: .now() + 1) {}
            return self.streamingBinding!
        }
    }

    private func basicSplitConfig() -> SplitClientConfig {
        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 9999
        splitConfig.segmentsRefreshRate = 9999
        splitConfig.impressionRefreshRate = 999999
        splitConfig.sdkReadyTimeOut = 3000
        splitConfig.eventsPushRate = 999999
        // splitConfig.isDebugModeEnabled = true
        return splitConfig
    }

    private func setupFactory(database: SplitDatabase? = nil) {
        // When splits and connection available, ready from cache and Ready should be fired
        let splitDatabase = database ?? TestingHelper.createTestDatabase(name: "multi_client_the_1st", queue: dbqueue)

        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        let httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        let splitConfig = basicSplitConfig()
        splitConfig.trafficType = trafficType
        splitConfig.logLevel = TestingHelper.testLogLevel

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(splitDatabase)

        factory = builder.setApiKey(IntegrationHelper.dummyApiKey).setKey(key)
            .setConfig(splitConfig).build()!
    }

    private func event(from data: Data?) -> [EventDTO]? {
        guard let data = data else { return nil }
        do {
            return try Json.dynamicDecodeFrom(json: data.stringRepresentation, to: [EventDTO].self)
        } catch {
            print(error)
        }
        return nil
    }

    private func impressions(from data: Data?) -> [KeyImpression]? {
        guard let data = data else { return nil }
        do {
            let tests = try Json.decodeFrom(json: data.stringRepresentation, to: [ImpressionsTest].self)
            return tests.flatMap { $0.keyImpressions }
        } catch {
            print(error)
        }
        return nil
    }
}
