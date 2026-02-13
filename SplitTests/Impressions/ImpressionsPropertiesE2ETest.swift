//
//  ImpressionsPropertiesE2ETest.swift
//  SplitTests
//
//  Copyright 2025 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class ImpressionsPropertiesE2ETest: XCTestCase {

    var httpClient: HttpClient!
    let apiKey = IntegrationHelper.dummyApiKey
    let userKey = IntegrationHelper.dummyUserKey
    var isSseAuthHit = false
    var isSseHit = false
    var streamingBinding: TestStreamResponseBinding?
    var firstSplitHit = true
    var sseExp: XCTestExpectation!
    var impExp: XCTestExpectation?
    var countExp: XCTestExpectation?
    var impressions: [String: [KeyImpression]]!
    var counts: [String: Int]!
    let queue = DispatchQueue(label: "queue", target: .test)
    var db: SplitDatabase!
    var requestBodies: [String] = []
    var postedImpressionsCount = 0

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: buildTestDispatcher(),
                                                          streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        impressions = [String: [KeyImpression]]()
        counts = [String: Int]()
        sseExp = XCTestExpectation(description: "Sse conn")
        impExp = nil
        requestBodies = []
        postedImpressionsCount = 0
    }

    /**
     Scenario: treatment evaluations with impression properties account for all impressions

     Given an SDK client initialized with mocked split and segment endpoints
     And impressions refresh rate set to 5 seconds
     And an impressions endpoint spy that counts posted impressions
     When getTreatment is called in a loop with EvaluationOptions(properties)
     And the loop stops early at a random iteration
     Or the loop completes all iterations and a fallback flush is triggered
     Then each iteration returns the expected treatment
     And elapsed time is greater than zero
     And impression listener count equals tracked evaluations
     And tracked evaluations is less than db impressions plus posted impressions (no loss)
     */
    func testTreatmentLoopWithImpressionPropertiesAndRandomFlushAccounting() {
        let iterations = 10000
        let listenerQueue = DispatchQueue(label: "impression-properties-listener-count")
        var listenerImpressionsCount = 0
        let client = setupClientFileBacked(
            mode: "OPTIMIZED",
            databaseName: "impressions_properties_random_flush_e2e"
        ) { config in
            config.impressionRefreshRate = 5
            config.impressionListener = { _ in
                listenerQueue.sync {
                    listenerImpressionsCount += 1
                }
            }
        }
        let minFlushIteration = max(1, iterations / 5)
        let flushAtIteration = Int.random(in: minFlushIteration..<iterations)
        var randomFlushInvoked = false

        var trackedEvaluations = 0
        var evaluatedIterations = 0
        let start = Date().timeIntervalSince1970
        for i in 0..<iterations {
            let properties: [String: Any] = [
                "iteration": i,
                "bucket": i % 10,
                "is_even": i % 2 == 0,
                "tag": "perf_\(i)"
            ]
            let evalOptions = EvaluationOptions(properties: properties)
            let treatment = client.getTreatment("FACUNDO_TEST", attributes: nil, evaluationOptions: evalOptions)
            XCTAssertTrue(treatment == "off",
                          "Unexpected treatment value: \(treatment)")
            if treatment == "off" {
                trackedEvaluations += 1
            }
            evaluatedIterations += 1
            if !randomFlushInvoked && i >= flushAtIteration && Int.random(in: 0..<100) < 20 {
                randomFlushInvoked = true
                client.flush()
                break
            }
        }
        let elapsedMs = (Date().timeIntervalSince1970 - start) * 1000.0

        // Ensure exactly one flush per test run
        if !randomFlushInvoked {
            client.flush()
        }

        var dbCount = 0
        var postedCount = 0
        var lastDbCount = -1
        var lastPostedCount = -1
        var stableSamples = 0
        let quiescenceStart = Date().timeIntervalSince1970
        let quiescenceDeadline = Date().timeIntervalSince1970 + 60.0
        while Date().timeIntervalSince1970 < quiescenceDeadline {
            dbCount = db.impressionDao.getBy(createdAt: 0,
                                             status: StorageRecordStatus.active,
                                             maxRows: 1_000_000).count
            queue.sync {
                postedCount = postedImpressionsCount
            }

            if dbCount == lastDbCount && postedCount == lastPostedCount {
                stableSamples += 1
                if stableSamples >= 10 {
                    break
                }
            } else {
                stableSamples = 0
                lastDbCount = dbCount
                lastPostedCount = postedCount
            }
            usleep(500_000)
        }
        _ = (Date().timeIntervalSince1970 - quiescenceStart) * 1000.0

        dbCount = db.impressionDao.getBy(createdAt: 0,
                                         status: StorageRecordStatus.active,
                                         maxRows: 1_000_000).count
        queue.sync {
            postedCount = postedImpressionsCount
        }
        var listenerCount = 0
        listenerQueue.sync {
            listenerCount = listenerImpressionsCount
        }

        XCTAssertGreaterThan(elapsedMs, 0)
        XCTAssertEqual(trackedEvaluations, listenerCount,
                       "Tracked evaluations should equal impression listener count")
        XCTAssertTrue(trackedEvaluations <= dbCount + postedCount,
                       "Tracked evaluations \(trackedEvaluations) should be equal or less than db + posted impressions (no loss) (\(dbCount) + \(postedCount))")

        cleanupClient(client)
    }

    /**
     Scenario: no impressions are lost when client is destroyed during in-flight post

     Given an SDK client initialized with mocked split and segment endpoints
     And impressions refresh rate set to 999 seconds (prevent automatic flush)
     And the impressions HTTP endpoint is configured to block responses via semaphore
     When getTreatment is called multiple times to generate impressions
     And flush() is called to trigger impression posting
     And the test waits for the HTTP post to start
     And destroy() is called while the HTTP response is still blocked
     Then all impressions are accounted for: either posted or still in DB (recoverable).
     */
    func testImpressionsNotLostWhenDestroyedDuringInflightPost() {
        let databaseName = "impressions_orphan_destroy_e2e"
        let impressionPostStarted = XCTestExpectation(description: "Impression post started")
        let impressionPostSemaphore = DispatchSemaphore(value: 0)
        var postReceivedCount = 0
        let postQueue = DispatchQueue(label: "orphan-test-post-queue")

        let dispatcher = buildOrphanTestDispatcher { request in
            impressionPostStarted.fulfill()
            impressionPostSemaphore.wait()
            postQueue.sync {
                postReceivedCount += self.parseImpressionCount(from: request)
            }
            return TestDispatcherResponse(code: 200)
        }

        let httpClient = buildOrphanHttpClient(dispatcher: dispatcher)
        setupOrphanTestDatabase(name: databaseName)
        let client = buildOrphanTestClient(httpClient: httpClient, matchingKey: userKey)

        // Generate impressions
        let evaluationCount = 200
        generateImpressions(client: client, count: evaluationCount)
        usleep(2_000_000)

        // Verify impressions are in DB
        let impressionsBeforeFlush = queryImpressionCount()
        print("SplitSDK - ORPHAN_TEST impressionsBeforeFlush=\(impressionsBeforeFlush)")
        XCTAssertEqual(evaluationCount, impressionsBeforeFlush, "All impressions should be in DB before flush")

        // Trigger flush — this will pop() rows (marking them deleted) and start HTTP post
        client.flush()
        wait(for: [impressionPostStarted], timeout: 10)

        // Destroy the client while the HTTP post is still blocked
        cleanupClient(client)

        // Check DB and post state BEFORE unblocking the HTTP response.
        let impressionsAfterDestroy = queryImpressionCount()
        var postReceivedAfterDestroy = 0
        postQueue.sync { postReceivedAfterDestroy = postReceivedCount }

        print("SplitSDK - ORPHAN_TEST impressionsAfterDestroy=\(impressionsAfterDestroy), postReceivedAfterDestroy=\(postReceivedAfterDestroy), evaluationCount=\(evaluationCount)")

        // All impressions must be accounted for: either posted or still in DB
        // so a future flush can retry them.
        XCTAssertEqual(evaluationCount, impressionsAfterDestroy + postReceivedAfterDestroy,
                       "All impressions must be accounted for: either posted or still in DB")

        // Unblock the HTTP response so the blocked worker thread can finish
        impressionPostSemaphore.signal()
        usleep(500_000)

        removeDatabaseFiles(databaseName: databaseName)
    }

    /**
     Scenario: a second client on the same DB recovers orphaned impressions from the first

     This is a variant of testImpressionsNotLostWhenDestroyedDuringInflightPost.
     After Client A is destroyed during an in-flight post, its impressions remain in
     the database. A second factory/client is created on the same database. Client B
     does its own evaluations and flushes. We verify that:
     - Client B posts both its OWN and the recovered impressions from Client A
     - No impressions remain in the database after Client B flushes
     */
    func testOrphanedImpressionsRecoveredByNewClient() {
        let databaseName = "impressions_orphan_new_client_e2e"
        let impressionPostStarted = XCTestExpectation(description: "Impression post started")
        let impressionPostSemaphore = DispatchSemaphore(value: 0)
        let clientBPostedExp = XCTestExpectation(description: "Client B posted expected impressions")
        var postReceivedCount = 0
        var clientBPostReceivedCount = 0
        var isClientBPhase = false
        let postQueue = DispatchQueue(label: "orphan-new-client-post-queue")
        var expectedPostedByB = 0
        var clientBPostedExpFulfilled = false

        let dispatcher = buildOrphanTestDispatcher { request in
            if !isClientBPhase {
                // Client A phase: block the response
                impressionPostStarted.fulfill()
                impressionPostSemaphore.wait()
                postQueue.sync {
                    postReceivedCount += self.parseImpressionCount(from: request)
                }
                return TestDispatcherResponse(code: 200)
            } else {
                // Client B phase: respond immediately and count until expected total is reached.
                postQueue.sync {
                    clientBPostReceivedCount += self.parseImpressionCount(from: request)
                    if !clientBPostedExpFulfilled,
                       expectedPostedByB > 0,
                       clientBPostReceivedCount >= expectedPostedByB {
                        clientBPostedExpFulfilled = true
                        clientBPostedExp.fulfill()
                    }
                }
                return TestDispatcherResponse(code: 200)
            }
        }

        // --- Client A phase ---
        let httpClientA = buildOrphanHttpClient(dispatcher: dispatcher)
        setupOrphanTestDatabase(name: databaseName)
        let clientA = buildOrphanTestClient(httpClient: httpClientA, matchingKey: userKey)

        let evaluationCountA = 200
        generateImpressions(client: clientA, count: evaluationCountA)
        usleep(2_000_000)

        // Flush Client A → pop marks rows as deleted → HTTP blocks
        clientA.flush()
        wait(for: [impressionPostStarted], timeout: 10)

        // Destroy Client A while HTTP is blocked
        cleanupClient(clientA)

        // Unblock the HTTP response (too late — destroy already happened)
        impressionPostSemaphore.signal()
        usleep(500_000)

        // Verify Client A's impressions are still in DB
        let impressionsAfterDestroy = queryImpressionCount()
        print("SplitSDK - ORPHAN_NEW_CLIENT impressionsAfterDestroy=\(impressionsAfterDestroy)")

        // --- Client B phase ---
        isClientBPhase = true
        let httpClientB = buildOrphanHttpClient(dispatcher: dispatcher)
        let clientB = buildOrphanTestClient(httpClient: httpClientB, matchingKey: "client_b_key")

        let evaluationCountB = 20
        generateImpressions(client: clientB, count: evaluationCountB, startIndex: evaluationCountA)
        usleep(2_000_000)

        // Flush Client B
        // Client B is only expected to post impressions that are ACTIVE in the DB at startup
        // (leftover from Client A) plus its own generated impressions. Impressions already
        // sent by Client A's in-flight request are not expected to be re-posted by Client B.
        expectedPostedByB = impressionsAfterDestroy + evaluationCountB
        clientB.flush()
        wait(for: [clientBPostedExp], timeout: 15)
        usleep(1_000_000)

        // Final state
        var finalClientBPostCount = 0
        var finalClientAPostCount = 0
        postQueue.sync {
            finalClientBPostCount = clientBPostReceivedCount
            finalClientAPostCount = postReceivedCount
        }
        let finalImpressions = queryImpressionCount()

        print("SplitSDK - ORPHAN_NEW_CLIENT clientAPosted=\(finalClientAPostCount), clientBPosted=\(finalClientBPostCount), finalImpressions=\(finalImpressions)")

        // Client B should post leftover ACTIVE impressions from Client A plus its own.
        XCTAssertEqual(impressionsAfterDestroy + evaluationCountB, finalClientBPostCount,
                       "Client B should post its own impressions plus active leftover impressions from Client A")

        // Across both clients, all evaluations should be accounted for by posted impressions.
        XCTAssertEqual(evaluationCountA + evaluationCountB, finalClientAPostCount + finalClientBPostCount,
                       "All impressions should be posted across Client A (in-flight) and Client B (recovered active)")

        // No impressions should remain in DB
        XCTAssertEqual(0, finalImpressions,
                       "No impressions should remain in DB after Client B flushes")

        removeDatabaseFiles(databaseName: databaseName)
    }

    /**
     Scenario: a second client recovers impressions that failed to post from the first (no interruption)

     Given Client A generates impressions and flushes
     And the impressions HTTP POST fails with a 500 error (not interrupted)
     And the impressions remain in the database after the failed flush
     And Client A is destroyed normally after the failed flush completes
     When a second factory/client (Client B) is created on the same database
     And Client B generates its own impressions and flushes
     Then Client B posts both Client A's recovered impressions and its own
     And no impressions remain in the database.
     */
    func testFailedImpressionsRecoveredByNewClient() {
        let databaseName = "impressions_failed_recovery_e2e"
        let clientAPostAttempted = XCTestExpectation(description: "Client A post attempted")
        let clientBPostedAllExp = XCTestExpectation(description: "Client B posted all impressions")

        let postQueue = DispatchQueue(label: "failed-recovery-post-queue")
        var isClientBPhase = false
        var clientBPostedCount = 0
        var clientBExpFulfilled = false

        let evaluationCountA = 50
        let evaluationCountB = 20
        let expectedTotalPostedByB = evaluationCountA + evaluationCountB

        let dispatcher = buildOrphanTestDispatcher { request in
            if !isClientBPhase {
                // Client A phase: fail the POST with 500 (should be recovered by setActive()).
                clientAPostAttempted.fulfill()
                return TestDispatcherResponse(code: 500)
            }

            // Client B phase: succeed and count all impressions (Client A recovered + Client B generated).
            postQueue.sync {
                clientBPostedCount += self.parseImpressionCount(from: request)
                if !clientBExpFulfilled && clientBPostedCount >= expectedTotalPostedByB {
                    clientBExpFulfilled = true
                    clientBPostedAllExp.fulfill()
                }
            }
            return TestDispatcherResponse(code: 200)
        }

        // --- Client A phase ---
        setupOrphanTestDatabase(name: databaseName)
        let httpClientA = buildOrphanHttpClient(dispatcher: dispatcher)
        let clientA = buildOrphanTestClient(httpClient: httpClientA, matchingKey: userKey) { config in
            // Deterministic: avoid queue-size-triggered flushes and keep A in a single chunk.
            config.impressionsQueueSize = 10_000
            config.impressionsChunkSize = 100
        }

        generateImpressions(client: clientA, count: evaluationCountA)
        usleep(2_000_000)

        clientA.flush()
        wait(for: [clientAPostAttempted], timeout: 10)

        // Wait until impressions are back in DB after failed POST.
        let restoreDeadline = Date().timeIntervalSince1970 + 10.0
        while Date().timeIntervalSince1970 < restoreDeadline {
            let count = queryImpressionCount()
            if count == evaluationCountA {
                break
            }
            usleep(200_000)
        }

        let impressionsAfterFailedFlush = queryImpressionCount()
        XCTAssertEqual(evaluationCountA, impressionsAfterFailedFlush,
                       "All impressions should still be in DB after failed POST")

        cleanupClient(clientA)

        // --- Client B phase ---
        isClientBPhase = true
        let httpClientB = buildOrphanHttpClient(dispatcher: dispatcher)
        let clientB = buildOrphanTestClient(httpClient: httpClientB, matchingKey: "client_b_key") { config in
            config.impressionsQueueSize = 10_000
            config.impressionsChunkSize = 100
        }

        generateImpressions(client: clientB, count: evaluationCountB, startIndex: evaluationCountA)
        usleep(2_000_000)

        clientB.flush()
        wait(for: [clientBPostedAllExp], timeout: 15)

        // Wait until DB drains after successful post.
        let drainDeadline = Date().timeIntervalSince1970 + 10.0
        while Date().timeIntervalSince1970 < drainDeadline {
            let count = queryImpressionCount()
            if count == 0 {
                break
            }
            usleep(200_000)
        }

        postQueue.sync {
            XCTAssertEqual(expectedTotalPostedByB, clientBPostedCount,
                           "Client B should post both Client A's recovered and its own impressions")
        }

        let finalImpressions = queryImpressionCount()
        XCTAssertEqual(0, finalImpressions, "No impressions should remain in DB after successful flush")

        cleanupClient(clientB)
        removeDatabaseFiles(databaseName: databaseName)
    }

    func testImpressionsWithPropertiesAreNotDedupedInOptimizedMode() {
        runTest(mode: "OPTIMIZED", withProperties: true, expectDeduplication: false)
    }

    func testImpressionsWithoutPropertiesAreDedupedInOptimizedMode() {
        // Test that impressions without properties are deduped in OPTIMIZED mode
        runTest(mode: "OPTIMIZED", withProperties: false, expectDeduplication: true)
    }

    func testPropertiesAreIncludedInRequestBody() {
        let client = setupClient(mode: "OPTIMIZED")

        // Create test properties
        let properties: [String: Any] = ["test": "value", "number": 123]
        let evalOptions = EvaluationOptions(properties: properties)

        // Get treatment with properties
        _ = client.getTreatment("FACUNDO_TEST", attributes: nil, evaluationOptions: evalOptions)

        impExp = XCTestExpectation()
        client.flush()

        wait(for: [impExp!], timeout: 10)

        // Verify properties in request body
        XCTAssertFalse(requestBodies.isEmpty, "Request bodies should not be empty")

        // Check if properties are included in the request body as a stringified JSON
        let containsProperties = requestBodies.contains { body in
            return body.contains("\"properties\":")
        }
        XCTAssertTrue(containsProperties, "Request body should contain properties field")

        // Check if the properties are properly stringified
        let containsPropertiesValue = requestBodies.contains { body in
            print(body)
            return body.contains("\\\"test\\\":\\\"value\\\"") && body.contains("\\\"number\\\":123")
        }
        XCTAssertTrue(containsPropertiesValue, "Request body should contain the correct property values")

        cleanupClient(client)
    }

    func testNoImpressionsAreTrackedInNoneMode() {
        // Test that no impressions are tracked in NONE mode
        let client = setupClient(mode: "NONE")

        // Create test properties
        let properties: [String: Any] = ["test": "value", "number": 123]
        let evalOptions = EvaluationOptions(properties: properties)

        // Get treatment with properties
        _ = client.getTreatment("FACUNDO_TEST", attributes: nil, evaluationOptions: evalOptions)

        // Get treatment without properties
        _ = client.getTreatment("test_string_without_attr")

        // Set up expectation to detect if impressions are sent
        impExp = XCTestExpectation()
        impExp?.isInverted = true // We expect this not to be fulfilled

        // Flush to trigger any potential impression sending
        client.flush()

        // Wait a short time to see if any impressions are sent
        wait(for: [impExp!], timeout: 1)

        // Verify no impressions were tracked
        XCTAssertEqual(0, requestBodies.count, "No impression requests should be made in NONE mode")

        cleanupClient(client)
    }

    func testPropertiesArePresentInImpressionListener() {
        // Create expectations for the impression listener
        let withPropertiesExpectation = XCTestExpectation(description: "Impression with properties")
        let withoutPropertiesExpectation = XCTestExpectation(description: "Impression without properties")

        // Track which feature flags we've seen in the listener
        var seenFeatureFlags = Set<String>()

        // Setup a client with an impression listener
        let client = setupClientWithImpressionListener { impression in
            // Determine which feature flag this is for
            guard let feature = impression.feature else {
                XCTFail("Feature name should not be nil")
                return
            }

            seenFeatureFlags.insert(feature)

            if feature == "FACUNDO_TEST" {
                withPropertiesExpectation.fulfill()

                XCTAssertNotNil(impression.properties, "Properties should not be nil for evaluation with properties")

                if let propertiesString = impression.properties {
                    XCTAssertTrue(propertiesString.contains("test"), "Properties should contain 'test' key")
                    XCTAssertTrue(propertiesString.contains("value"), "Properties should contain 'value'")
                    XCTAssertTrue(propertiesString.contains("number"), "Properties should contain 'number' key")
                    XCTAssertTrue(propertiesString.contains("123"), "Properties should contain '123'")
                }
            } else if feature == "test_string_without_attr" {
                withoutPropertiesExpectation.fulfill()

                XCTAssertNil(impression.properties, "Properties should be nil for evaluation without properties")
            }
        }

        let properties: [String: Any] = ["test": "value", "number": 123]
        let evalOptions = EvaluationOptions(properties: properties)

        _ = client.getTreatment("FACUNDO_TEST", attributes: nil, evaluationOptions: evalOptions)

        _ = client.getTreatment("test_string_without_attr")

        wait(for: [withPropertiesExpectation, withoutPropertiesExpectation], timeout: 5)

        XCTAssertTrue(seenFeatureFlags.contains("FACUNDO_TEST"), "Should have seen impression for FACUNDO_TEST")
        XCTAssertTrue(seenFeatureFlags.contains("test_string_without_attr"), "Should have seen impression for test_string_without_attr")

        cleanupClient(client)
    }

    private func runTest(mode: String, withProperties: Bool, expectDeduplication: Bool) {
        let client = setupClient(mode: mode)
        
        let featureName = "FACUNDO_TEST"
        let evalOptions = withProperties ?
            EvaluationOptions(properties: ["test": "value"]) : nil

        let treatmentTimes = 5
        for _ in 0..<treatmentTimes {
            _ = client.getTreatment(featureName, attributes: nil, evaluationOptions: evalOptions)
        }

        impExp = XCTestExpectation()
        
        if expectDeduplication {
            countExp = XCTestExpectation()
        }
        
        client.flush()
        
        wait(for: [impExp!], timeout: 10)
        if expectDeduplication {
            wait(for: [countExp!], timeout: 10)
            sleep(1)
        }

        // Check the number of impressions recorded
        let expectedCount = expectDeduplication ? 1 : treatmentTimes
        XCTAssertEqual(expectedCount, impressions[featureName]?.count ?? 0,
                       "Expected \(expectedCount) impressions for feature \(featureName)")
        
        if expectDeduplication {
            XCTAssertEqual(treatmentTimes - 1, counts[featureName] ?? 0,
                            "Expected \(treatmentTimes - 1) impression count for feature \(featureName)")
        }

        cleanupClient(client)
    }
    
    private func setupClient(mode: String) -> SplitClient {
        return setupClient(mode: mode, configCustomizer: nil)
    }

    private func setupClient(mode: String,
                             configCustomizer: ((SplitClientConfig) -> Void)?) -> SplitClient {
        let notificationHelper = NotificationHelperStub()
        db = TestingHelper.createTestDatabase(name: "test")

        let splitConfig = createSplitConfig()
        splitConfig.impressionsMode = mode
        configCustomizer?(splitConfig)
        
        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(db)
        _ = builder.setNotificationHelper(notificationHelper)
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 20)
        
        return client
    }

    private func setupClientFileBacked(mode: String,
                                       databaseName: String,
                                       configCustomizer: ((SplitClientConfig) -> Void)?) -> SplitClient {
        let notificationHelper = NotificationHelperStub()
        db = createCleanFileBackedDatabase(name: databaseName)

        let splitConfig = createSplitConfig()
        splitConfig.impressionsMode = mode
        configCustomizer?(splitConfig)

        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(db)
        _ = builder.setNotificationHelper(notificationHelper)
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client
        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }
        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 20)
        return client
    }

    private func createCleanFileBackedDatabase(name: String) -> SplitDatabase {
        removeDatabaseFiles(databaseName: name)
        guard let helper = CoreDataHelperBuilder.build(databaseName: name) else {
            fatalError("Failed to create file-backed test DB: \(name)")
        }
        return TestingHelper.createTestDatabase(name: name, helper: helper)
    }

    private func removeDatabaseFiles(databaseName: String) {
        guard let cachesUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last else {
            return
        }

        let base = "\(databaseName).\(ServiceConstants.databaseExtension)"
        let dbUrls = [
            cachesUrl.appendingPathComponent(base),
            cachesUrl.appendingPathComponent(base + "-wal"),
            cachesUrl.appendingPathComponent(base + "-shm")
        ]

        for url in dbUrls {
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
    
    private func setupClientWithImpressionListener(_ listener: @escaping SplitImpressionListener) -> SplitClient {
        let notificationHelper = NotificationHelperStub()
        db = TestingHelper.createTestDatabase(name: "test")

        let splitConfig = createSplitConfig()
        splitConfig.impressionsMode = "OPTIMIZED"
        splitConfig.impressionListener = listener

        let key: Key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(db)
        _ = builder.setNotificationHelper(notificationHelper)
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY Expectation")

        client.on(event: SplitEvent.sdkReady) {
            sdkReadyExpectation.fulfill()
        }

        client.on(event: SplitEvent.sdkReadyTimedOut) {
            sdkReadyExpectation.fulfill()
        }

        wait(for: [sdkReadyExpectation, sseExp], timeout: 20)

        return client
    }

    private func createSplitConfig() -> SplitClientConfig {
        let splitConfig = SplitClientConfig()
        splitConfig.featuresRefreshRate = 30
        splitConfig.segmentsRefreshRate = 30
        splitConfig.sdkReadyTimeOut = 60000
        splitConfig.eventsPerPush = 999999
        splitConfig.eventsQueueSize = 99999
        splitConfig.eventsPushRate = 99999
        splitConfig.logLevel = .verbose
        return splitConfig
    }

    private func cleanupClient(_ client: SplitClient) {
        let semaphore = DispatchSemaphore(value: 0)
        client.destroy(completion: {
            _ = semaphore.signal()
        })
        semaphore.wait()
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                if self.firstSplitHit {
                    self.firstSplitHit = false
                    return TestDispatcherResponse(code: 200, data: Data(self.loadSplitsChangeFile().utf8))
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 99999, till: 99999).utf8))
            }
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                self.isSseAuthHit = true
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            if request.isImpressionsEndpoint() {
                self.queue.sync {
                    if let body = request.body?.stringRepresentation.utf8 {
                        let bodyString = String(body)
                        self.requestBodies.append(bodyString)

                        if let tests = try? Json.decodeFrom(json: bodyString, to: [ImpressionsTest].self) {
                            for test in tests {
                                self.postedImpressionsCount += test.keyImpressions.count
                                var imps = [KeyImpression]()
                                if let prevImp = self.impressions[test.testName] {
                                    imps.append(contentsOf: prevImp)
                                }
                                imps.append(contentsOf: test.keyImpressions)
                                self.impressions.updateValue(imps, forKey: test.testName)
                            }
                        }
                    }
                    if let exp = self.impExp {
                        exp.fulfill()
                    }
                }
                return TestDispatcherResponse(code: 200)
            }

            if request.isImpressionsCountEndpoint() {
                self.queue.sync {
                    if let exp = self.countExp {
                        exp.fulfill()
                    }
                    if let body = request.body?.stringRepresentation.utf8 {
                        if let impressionsCount = try? Json.decodeFrom(json: String(body), to: ImpressionsCount.self) {
                            for countPerFeature in impressionsCount.perFeature {
                                self.counts[countPerFeature.feature] = countPerFeature.count + (self.counts[countPerFeature.feature] ?? 0)
                            }
                        }
                    }
                }
                return TestDispatcherResponse(code: 200)
            }

            return TestDispatcherResponse(code: 200)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.isSseHit = true
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            self.sseExp.fulfill()
            return self.streamingBinding!
        }
    }

    private func loadSplitsChangeFile() -> String {
        guard let splitJson = FileHelper.readDataFromFile(sourceClass: self, name: "splitchanges_1", type: "json") else {
            return IntegrationHelper.emptySplitChanges(since: 99999, till: 99999)
        }
        return splitJson
    }

    // MARK: - Orphan Test Helpers

    /// Parses the number of individual impressions from an HTTP request body.
    private func parseImpressionCount(from request: HttpDataRequest) -> Int {
        guard let body = request.body?.stringRepresentation.utf8 else { return 0 }
        let bodyString = String(body)
        guard let tests = try? Json.decodeFrom(json: bodyString, to: [ImpressionsTest].self) else { return 0 }
        return tests.reduce(0) { $0 + $1.keyImpressions.count }
    }

    /// Builds a dispatcher that handles standard endpoints and delegates impressions to the given handler.
    private func buildOrphanTestDispatcher(
        impressionHandler: @escaping (HttpDataRequest) -> TestDispatcherResponse
    ) -> HttpClientTestDispatcher {
        return { request in
            if request.isSplitEndpoint() {
                if self.firstSplitHit {
                    self.firstSplitHit = false
                    return TestDispatcherResponse(code: 200, data: Data(self.loadSplitsChangeFile().utf8))
                }
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptySplitChanges(since: 99999, till: 99999).utf8))
            }
            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }
            if request.isAuthEndpoint() {
                self.isSseAuthHit = true
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }
            if request.isImpressionsEndpoint() {
                return impressionHandler(request)
            }
            if request.isImpressionsCountEndpoint() {
                return TestDispatcherResponse(code: 200)
            }
            return TestDispatcherResponse(code: 200)
        }
    }

    /// Creates an HttpClient from a dispatcher, with a fresh session and streaming handler.
    private func buildOrphanHttpClient(dispatcher: @escaping HttpClientTestDispatcher) -> HttpClient {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(dispatcher: dispatcher,
                                                          streamingHandler: buildStreamingHandler())
        return DefaultHttpClient(session: session, requestManager: reqManager)
    }

    /// Sets up a clean file-backed database for orphan tests.
    private func setupOrphanTestDatabase(name: String) {
        removeDatabaseFiles(databaseName: name)
        guard let helper = CoreDataHelperBuilder.build(databaseName: name) else {
            XCTFail("Failed to create file-backed DB")
            return
        }
        db = TestingHelper.createTestDatabase(name: name, helper: helper)
    }

    /// Builds a SplitClient configured for orphan impression tests, resetting SSE/split state.
    private func buildOrphanTestClient(httpClient: HttpClient,
                                       matchingKey: String,
                                       configCustomizer: ((SplitClientConfig) -> Void)? = nil) -> SplitClient {
        firstSplitHit = true
        sseExp = XCTestExpectation(description: "SSE conn")

        let splitConfig = createSplitConfig()
        splitConfig.impressionsMode = "OPTIMIZED"
        splitConfig.impressionRefreshRate = 999
        configCustomizer?(splitConfig)

        let key = Key(matchingKey: matchingKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(db)
        _ = builder.setNotificationHelper(NotificationHelperStub())
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        let client = factory.client

        let sdkReadyExpectation = XCTestExpectation(description: "SDK READY")
        client.on(event: SplitEvent.sdkReady) { sdkReadyExpectation.fulfill() }
        client.on(event: SplitEvent.sdkReadyTimedOut) { sdkReadyExpectation.fulfill() }
        wait(for: [sdkReadyExpectation, sseExp], timeout: 20)

        return client
    }

    /// Generates impressions with unique properties by calling getTreatment in a loop.
    private func generateImpressions(client: SplitClient, count: Int, startIndex: Int = 0) {
        for i in 0..<count {
            let properties: [String: Any] = ["iteration": startIndex + i]
            let evalOptions = EvaluationOptions(properties: properties)
            let treatment = client.getTreatment("FACUNDO_TEST", attributes: nil, evaluationOptions: evalOptions)
            XCTAssertEqual("off", treatment, "Expected 'off' treatment")
        }
    }

    /// Queries the database for total impression count.
    private func queryImpressionCount() -> Int {
        return db.impressionDao.getBy(createdAt: 0, status: StorageRecordStatus.active, maxRows: 1_000_000).count
    }
}
