@testable import Split
import XCTest

final class RolloutCacheManagerIntegrationTest: XCTestCase {
    private var httpClient: HttpClient!
    private let apiKey = IntegrationHelper.dummyApiKey
    private let userKey = "key"
    private var firstSplitHit: Bool!
    private var streamingBinding: TestStreamResponseBinding?
    private var notificationHelper: NotificationHelperStub?
    private var testDb: SplitDatabase!
    private var enableRequest: Bool!
    private let lock = NSLock()

    override func setUp() {
        let session = HttpSessionMock()
        let reqManager = HttpRequestManagerTestDispatcher(
            dispatcher: buildTestDispatcher(),
            streamingHandler: buildStreamingHandler())
        httpClient = DefaultHttpClient(session: session, requestManager: reqManager)
        notificationHelper = NotificationHelperStub()
        testDb = TestingHelper.createTestDatabase(name: "test")
        firstSplitHit = true
        enableRequest = false
    }

    func testExpirationPeriodIsUsed() {
        test(
            timestampDaysAgo: getTimestampDaysAgo(days: 1),
            configBuilder: RolloutCacheConfiguration.builder().set(expirationDays: 1))
    }

    func testClearOnInitClearCacheOnStartup() {
        test(
            timestampDaysAgo: getTimestampDaysAgo(days: 0),
            configBuilder: RolloutCacheConfiguration.builder().set(clearOnInit: true))
    }

    func testRepeatedInitWithClearOnInitSetToTrueDoesNotClearIfMinDaysHasNotElapsed() {
        // preload DB with update timestamp of now
        preloadDB(updateTimestamp: getTimestampDaysAgo(days: 0), lastClearTimestamp: 0, changeNumber: 8000)

        // Track initial values
        let initialFlags = testDb.splitDao.getAll()
        let initialSegments = testDb.mySegmentsDao.getBy(userKey: userKey)
        let initialLargeSegments = testDb.myLargeSegmentsDao.getBy(userKey: userKey)
        let initialChangeNumber = testDb.generalInfoDao.longValue(info: .splitsChangeNumber)

        // Initialize SDK
        let factory = getFactory(rolloutConfig: RolloutCacheConfiguration.builder().set(clearOnInit: true).build())
        sleep(1)

        // Track intermediate values
        let intermediateFlags = testDb.splitDao.getAll()
        let intermediateSegments = testDb.mySegmentsDao.getBy(userKey: userKey)
        let intermediateLargeSegments = testDb.myLargeSegmentsDao.getBy(userKey: userKey)
        let intermediateChangeNumber = testDb.generalInfoDao.longValue(info: .splitsChangeNumber)

        // Resume server responses after tracking DB values
        lock.lock()
        enableRequest = true
        lock.unlock()

        // Wait for ready
        let readyExp = XCTestExpectation(description: "SDK READY Expectation")
        factory.client.on(event: SplitEvent.sdkReady) {
            readyExp.fulfill()
        }
        wait(for: [readyExp], timeout: 15)

        // Destroy factory
        let destroyExp = XCTestExpectation(description: "Destroy Expectation")
        factory.client.destroy(completion: {
            destroyExp.fulfill()
        })

        wait(for: [destroyExp], timeout: 15)

        // Initialize SDK again
        lock.lock()
        enableRequest = false
        lock.unlock()

        preloadDB(updateTimestamp: nil, lastClearTimestamp: nil, changeNumber: nil)
        let factory2 = getFactory(rolloutConfig: RolloutCacheConfiguration.builder().set(clearOnInit: true).build())
        sleep(1)

        // Track intermediate values
        let factory2Flags = testDb.splitDao.getAll()
        let factory2Segments = testDb.mySegmentsDao.getBy(userKey: userKey)
        let factory2LargeSegments = testDb.myLargeSegmentsDao.getBy(userKey: userKey)
        let factory2ChangeNumber = testDb.generalInfoDao.longValue(info: .splitsChangeNumber)

        // initial values
        XCTAssertEqual(1, initialFlags.count)
        XCTAssertEqual(2, initialSegments?.segments.count ?? 0)
        XCTAssertFalse(initialSegments?.segments.isEmpty ?? true)
        XCTAssertFalse(initialLargeSegments?.segments.isEmpty ?? true)
        XCTAssertEqual(8000, initialChangeNumber)

        // values after clear
        XCTAssertEqual(0, intermediateFlags.count)
        XCTAssertTrue(intermediateSegments?.segments.isEmpty ?? true)
        XCTAssertTrue(intermediateLargeSegments?.segments.isEmpty ?? true)
        XCTAssertEqual(-1, intermediateChangeNumber)

        // values after second init (values were reinserted into DB); no clear should have happened
        XCTAssertEqual(1, factory2Flags.count)
        XCTAssertEqual(2, factory2Segments?.segments.count ?? 0)
        XCTAssertFalse(factory2Segments?.segments.isEmpty ?? true)
        XCTAssertFalse(factory2LargeSegments?.segments.isEmpty ?? true)
        XCTAssertEqual(99999, factory2ChangeNumber)
        XCTAssertTrue(0 < testDb.generalInfoDao.longValue(info: .rolloutCacheLastClearTimestamp) ?? -1)
    }

    private func test(timestampDaysAgo: Int64, configBuilder: RolloutCacheConfiguration.Builder) {
        let oldTimestamp = timestampDaysAgo
        preloadDB(updateTimestamp: oldTimestamp, lastClearTimestamp: 0, changeNumber: 8000)
        // Track initial values
        let initialFlags = testDb.splitDao.getAll()
        let initialSegments = testDb.mySegmentsDao.getBy(userKey: userKey)
        let initialLargeSegments = testDb.myLargeSegmentsDao.getBy(userKey: userKey)
        let initialChangeNumber = testDb.generalInfoDao.longValue(info: .splitsChangeNumber)

        // Initialize SDK
        let factory = getFactory(rolloutConfig: configBuilder.build())

        let readyExp = XCTestExpectation(description: "SDK READY Expectation")
        factory.client.on(event: SplitEvent.sdkReady) {
            readyExp.fulfill()
        }

        // Track final values
        verify(
            factory: factory,
            readyExp: readyExp,
            initialFlags: initialFlags,
            initialSegments: initialSegments,
            initialLargeSegments: initialLargeSegments,
            initialChangeNumber: initialChangeNumber)
    }

    private func preloadDB(updateTimestamp: Int64?, lastClearTimestamp: Int64?, changeNumber: Int64?) {
        let split = TestingHelper.buildSplit(name: "test_split", treatment: "test_treatment")
        testDb.splitDao.insertOrUpdate(split: split)
        if let updateTimestamp = updateTimestamp {
            testDb.generalInfoDao.update(info: .splitsUpdateTimestamp, longValue: updateTimestamp)
        }
        if let lastClearTimestamp = lastClearTimestamp {
            testDb.generalInfoDao.update(info: .rolloutCacheLastClearTimestamp, longValue: lastClearTimestamp)
        }
        if let changeNumber = changeNumber {
            testDb.generalInfoDao.update(info: .splitsChangeNumber, longValue: changeNumber)
        }
        testDb.mySegmentsDao.update(userKey: userKey, change: SegmentChange(segments: ["s1", "s2"], changeNumber: nil))
        testDb.myLargeSegmentsDao.update(
            userKey: userKey,
            change: SegmentChange(segments: ["l1", "l2"], changeNumber: nil))
    }

    private func loadSplitsChangeFile() -> String {
        guard let splitJson = FileHelper.readDataFromFile(sourceClass: self, name: "splitchanges_1", type: "json")
        else {
            return IntegrationHelper.emptySplitChanges(since: 99999, till: 99999)
        }
        return splitJson
    }

    private func verify(
        factory: SplitFactory,
        readyExp: XCTestExpectation,
        initialFlags: [Split],
        initialSegments: SegmentChange?,
        initialLargeSegments: SegmentChange?,
        initialChangeNumber: Int64?) {
        let finalFlags = testDb.splitDao.getAll()
        let finalSegments = testDb.mySegmentsDao.getBy(userKey: userKey)
        let finalLargeSegments = testDb.myLargeSegmentsDao.getBy(userKey: userKey)
        let finalChangeNumber = testDb.generalInfoDao.longValue(info: .splitsChangeNumber)

        // Resume responses after tracking DB Values
        lock.lock()
        enableRequest = true
        lock.unlock()

        // Wait for ready
        wait(for: [readyExp], timeout: 15)

        // Verify
        XCTAssertEqual(1, initialFlags.count)
        XCTAssertEqual(2, initialSegments?.segments.count ?? 0)
        XCTAssertFalse(initialSegments?.segments.isEmpty ?? true)
        XCTAssertFalse(initialLargeSegments?.segments.isEmpty ?? true)
        XCTAssertEqual(8000, initialChangeNumber)
        XCTAssertEqual(0, finalFlags.count)
        XCTAssertTrue(finalSegments?.segments.isEmpty ?? true)
        XCTAssertTrue(finalLargeSegments?.segments.isEmpty ?? true)
        XCTAssertEqual(-1, finalChangeNumber)
        XCTAssertTrue(0 < testDb.generalInfoDao.longValue(info: .rolloutCacheLastClearTimestamp) ?? -1)
    }

    private func getTimestampDaysAgo(days: Int) -> Int64 {
        return Date.secondsToDays(seconds: Date.now() - Int64(days * 86400))
    }

    private func getFactory(rolloutConfig: RolloutCacheConfiguration) -> SplitFactory {
        let splitConfig = SplitClientConfig()
        splitConfig.logLevel = .verbose
        splitConfig.streamingEnabled = false
        splitConfig.featuresRefreshRate = 1

        let key = Key(matchingKey: userKey)
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setHttpClient(httpClient)
        _ = builder.setReachabilityChecker(ReachabilityMock())
        _ = builder.setTestDatabase(testDb)
        _ = builder.setNotificationHelper(notificationHelper!)
        let factory = builder.setApiKey(apiKey).setKey(key)
            .setConfig(splitConfig).build()!

        return factory
    }

    private func buildTestDispatcher() -> HttpClientTestDispatcher {
        return { request in
            self.lock.lock()
            while !self.enableRequest {
                self.lock.unlock()
                Thread.sleep(forTimeInterval: 0.5)
                self.lock.lock()
            }
            self.lock.unlock()

            if request.isSplitEndpoint() {
                if self.firstSplitHit {
                    self.firstSplitHit = false
                    return TestDispatcherResponse(
                        code: 200,
                        data: Data(IntegrationHelper.emptySplitChanges(since: -1, till: 99999).utf8))
                }
                return TestDispatcherResponse(
                    code: 200,
                    data: Data(IntegrationHelper.emptySplitChanges(since: 99999, till: 99999).utf8))
            }

            if request.isMySegmentsEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.emptyMySegments.utf8))
            }

            if request.isAuthEndpoint() {
                return TestDispatcherResponse(code: 200, data: Data(IntegrationHelper.dummySseResponse().utf8))
            }

            if request.isImpressionsEndpoint() {
                return TestDispatcherResponse(code: 200)
            }

            if request.isImpressionsCountEndpoint() {
                return TestDispatcherResponse(code: 200)
            }

            if request.isUniqueKeysEndpoint() {
                return TestDispatcherResponse(code: 200)
            }
            return TestDispatcherResponse(code: 404)
        }
    }

    private func buildStreamingHandler() -> TestStreamResponseBindingHandler {
        return { request in
            self.streamingBinding = TestStreamResponseBinding.createFor(request: request, code: 200)
            return self.streamingBinding!
        }
    }
}
