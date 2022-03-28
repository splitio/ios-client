//
//  TreatmentManagerTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 05/07/2019.
//  Copyright © 2019 Split. All rights reserved.
//

//import Foundation
import XCTest
@testable import Split

class TreatmentManagerTest: XCTestCase {
    
    var validationLogger: ValidationMessageLogger!
    var splitsStorage: SplitsStorage!
    var mySegmentsStorage: MySegmentsStorageStub!
    var storageContainer: SplitStorageContainer!
    var client: InternalSplitClient!
    var attributesStorage: AttributesStorage!
    
    var impressionsLogger: ImpressionsLoggerStub!
    var telemetryProducer: TelemetryStorageStub!

    let userKey = Key(matchingKey: "key")
    let matchingKey = "the_key"
    var key: Key!
    
    var validationLoggerStub: ValidationMessageLoggerStub {
        return validationLogger as! ValidationMessageLoggerStub
    }
    
    override func setUp() {

        key = Key(matchingKey: matchingKey)
        impressionsLogger = ImpressionsLoggerStub()
        validationLogger = ValidationMessageLoggerStub()
        attributesStorage = DefaultAttributesStorage()
        telemetryProducer = TelemetryStorageStub()
        if storageContainer == nil {
            let splits = loadSplitsFile()
            let mySegments = ["s1", "s2", "test_copy"]
            splitsStorage = SplitsStorageStub()
            splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: splits, archivedSplits: [],
                                                                   changeNumber: -1, updateTimestamp: 100))
            mySegmentsStorage = MySegmentsStorageStub()
            mySegmentsStorage.set(mySegments, forKey: userKey.matchingKey)
            storageContainer = SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "pepe"),
                                                     fileStorage: FileStorageStub(),
                                                     splitsStorage: splitsStorage,
                                                     persistentSplitsStorage: PersistentSplitsStorageStub(),
                                                     oneKeyMySegmentsStorage: ByKeyMySegmentsStorageStub(),
                                                     impressionsStorage: PersistentImpressionsStorageStub(),
                                                     impressionsCountStorage: PersistentImpressionsCountStorageStub(),
                                                     eventsStorage: PersistentEventsStorageStub(),
                                                     oneKeyAttributesStorage: OneKeyDefaultAttributesStorage(),
                                                     telemetryStorage: telemetryProducer,
                                                     mySegmentsStorage: mySegmentsStorage,
                                                     attributesStorage: attributesStorage)
        }
    }
    
    func testBasicEvaluationNoConfig() {
        let splitName = "FACUNDO_TEST"
        
        let treatmentManager = createTreatmentManager()
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, key: key, attributes: nil)
        let impression = impressionsLogger.impressions[splitName]
        
        
        XCTAssertNotNil(splitResult)
        XCTAssertEqual("off", splitResult.treatment)
        XCTAssertNil(splitResult.config)
        
        XCTAssertNotNil(impression)
        XCTAssertEqual(splitResult.treatment, impression?.treatment)
        XCTAssertEqual(matchingKey, impression?.keyName)
        XCTAssertEqual("in segment all", impression?.label)
        
        XCTAssertFalse(validationLoggerStub.hasError)
        XCTAssertFalse(validationLoggerStub.hasWarnings)
        XCTAssertEqual(1, telemetryProducer.methodLatencies[.treatmentWithConfig])
    }
    
    func testBasicEvaluationWithConfig() {
        let splitName = "Test_Save_1"

        let treatmentManager = createTreatmentManager()
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, key: key, attributes: nil)
        let impression = impressionsLogger.impressions[splitName]
        
        
        XCTAssertNotNil(splitResult)
        XCTAssertEqual("off", splitResult.treatment)
        XCTAssertEqual("{\"f1\":\"v1\"}", splitResult.config)
        
        XCTAssertNotNil(impression)
        XCTAssertEqual(splitResult.treatment, impression?.treatment)
        XCTAssertEqual(matchingKey, impression?.keyName)
        XCTAssertEqual("in segment all", impression?.label)
        
        XCTAssertFalse(validationLoggerStub.hasError)
        XCTAssertFalse(validationLoggerStub.hasWarnings)
    }
    
    func testKilledSplitWithConfig() {
        let splitName = "OldTest"

        let treatmentManager = createTreatmentManager()
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, key: key, attributes: nil)
        let impression = impressionsLogger.impressions[splitName]
        
        
        XCTAssertNotNil(splitResult)
        XCTAssertEqual("off", splitResult.treatment)
        XCTAssertEqual("{\"f1\":\"v1\"}", splitResult.config)
        
        XCTAssertNotNil(impression)
        XCTAssertEqual(splitResult.treatment, impression?.treatment)
        XCTAssertEqual(matchingKey, impression?.keyName)
        XCTAssertEqual("killed", impression?.label)
        
        XCTAssertFalse(validationLoggerStub.hasError)
        XCTAssertFalse(validationLoggerStub.hasWarnings)
        
    }
    
    func testBasicEvaluations() {
//        let thisKey = Key(matchingKey: "thekey")
        let thisKey = Key(matchingKey: matchingKey)

        mySegmentsStorage.set(["test_copy"], forKey: matchingKey)

        let splitNames = ["FACUNDO_TEST", "testo2222", "OldTest"]
        
        let treatmentManager = createTreatmentManager()
        let splitResults = treatmentManager.getTreatmentsWithConfig(splits: splitNames, key: thisKey, attributes: nil)
        
        let r1 = splitResults["FACUNDO_TEST"]
        let r2 = splitResults["testo2222"]
        let r3 = splitResults["OldTest"]
        
        let impressionsCount = impressionsLogger.impressions.count
        let imp1 = impressionsLogger.impressions[splitNames[0]]
        let imp2 = impressionsLogger.impressions[splitNames[1]]
        let imp3 = impressionsLogger.impressions[splitNames[2]]
        
        XCTAssertNotNil(r1)
        XCTAssertEqual("off", r1?.treatment)
        XCTAssertNil(r1?.config)
        
        XCTAssertNotNil(r2)
        XCTAssertEqual("pesto", r2?.treatment)
        XCTAssertNil(r2?.config)
        
        XCTAssertNotNil(r3)
        XCTAssertEqual("off", r3?.treatment)
        XCTAssertEqual("{\"f1\":\"v1\"}", r3?.config)
        
        XCTAssertEqual(3, impressionsCount)
        XCTAssertNotNil(imp1)
        XCTAssertNotNil(imp2)
        XCTAssertNotNil(imp3)
        
        XCTAssertEqual(r1?.treatment, imp1?.treatment)
        XCTAssertEqual(matchingKey, imp1?.keyName)
        XCTAssertEqual("in segment all", imp1?.label)
        
        XCTAssertFalse(validationLoggerStub.hasError)
        XCTAssertFalse(validationLoggerStub.hasWarnings)
    }
    
    func testNonExistingSplits() {
        let otherKey = Key(matchingKey: "nico_test")
        let splitName = "NON_EXISTING_1"
        let splitNames = ["NON_EXISTING_1", "NON_EXISTING_2", "NON_EXISTING_3"]
        
        let treatmentManager = createTreatmentManager()
        
        let treatment = treatmentManager.getTreatment(splitName, key: otherKey, attributes: nil)
        let treatmentList = treatmentManager.getTreatments(splits: splitNames, key: otherKey, attributes: nil)
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, key: otherKey, attributes: nil)
        let splitResults = treatmentManager.getTreatmentsWithConfig(splits: splitNames, key: otherKey, attributes: nil)

        XCTAssertEqual(0, impressionsLogger.impressions.count)
        assertControl(splitList: splitNames, treatment: treatment, treatmentList: treatmentList, splitResult: splitResult, splitResultList: splitResults)
        
        XCTAssertFalse(validationLoggerStub.hasError)
        XCTAssertTrue(validationLoggerStub.hasWarnings)
    }
    
    func testEmptySplits() {
        let otherKey = Key(matchingKey: "nico_test")
        let splitName = ""
        let splitNames: [String] = []
        
        let treatmentManager = createTreatmentManager()
        
        let treatment = treatmentManager.getTreatment(splitName, key: otherKey, attributes: nil)
        let treatmentList = treatmentManager.getTreatments(splits: splitNames, key: otherKey, attributes: nil)
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, key: otherKey, attributes: nil)
        let splitResults = treatmentManager.getTreatmentsWithConfig(splits: splitNames, key: otherKey, attributes: nil)
        
        
        XCTAssertEqual(0, impressionsLogger.impressions.count)
        assertControl(splitList: splitNames, treatment: treatment, treatmentList: treatmentList, splitResult: splitResult, splitResultList: splitResults)
        XCTAssertTrue(validationLoggerStub.hasError)
        XCTAssertFalse(validationLoggerStub.hasWarnings)
    }
    
    func testEmptyKey() {
        let otherKey = Key(matchingKey: "")
        let splitName = "FACUNDO_TEST"
        let splitNames = ["FACUNDO_TEST", "a_new_split_2", "benchmark_jw_1"]
        
        let treatmentManager = createTreatmentManager()
        
        let treatment = treatmentManager.getTreatment(splitName, key: otherKey, attributes: nil)
        let treatmentList = treatmentManager.getTreatments(splits: splitNames, key: otherKey, attributes: nil)
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, key: otherKey, attributes: nil)
        let splitResults = treatmentManager.getTreatmentsWithConfig(splits: splitNames, key: otherKey, attributes: nil)

        XCTAssertEqual(0, impressionsLogger.impressions.count)
        assertControl(splitList: splitNames, treatment: treatment, treatmentList: treatmentList, splitResult: splitResult, splitResultList: splitResults)
        XCTAssertTrue(validationLoggerStub.hasError)
        XCTAssertFalse(validationLoggerStub.hasWarnings)
    }
    
    func testLongKey() {
        let otherKey = Key(matchingKey: String(repeating: "p", count: 251))
        let splitName = "FACUNDO_TEST"
        let splitNames = ["FACUNDO_TEST", "a_new_split_2", "benchmark_jw_1"]
        
        let treatmentManager = createTreatmentManager()
        
        let treatment = treatmentManager.getTreatment(splitName, key: otherKey, attributes: nil)
        let treatmentList = treatmentManager.getTreatments(splits: splitNames, key: otherKey, attributes: nil)
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, key: otherKey, attributes: nil)
        let splitResults = treatmentManager.getTreatmentsWithConfig(splits: splitNames, key: otherKey, attributes: nil)
        
        XCTAssertEqual(0, impressionsLogger.impressions.count)
        assertControl(splitList: splitNames, treatment: treatment, treatmentList: treatmentList, splitResult: splitResult, splitResultList: splitResults)
        XCTAssertTrue(validationLoggerStub.hasError)
        XCTAssertFalse(validationLoggerStub.hasWarnings)
    }

    func testNoStoredAttributes() {
        let splitName = "FACUNDO_TEST"
        let splitNames = [splitName]
        let evaluator = EvaluatorStub()

        let treatmentManager = createTreatmentManager(evaluator: evaluator)

        let _ = treatmentManager.getTreatment(splitName, key: userKey, attributes: nil)
        let _ = treatmentManager.getTreatments(splits: splitNames, key: userKey, attributes: nil)
        let _ = treatmentManager.getTreatmentWithConfig(splitName, key: userKey, attributes: nil)
        let _ = treatmentManager.getTreatmentsWithConfig(splits: splitNames, key: userKey, attributes: nil)

        XCTAssertNil(evaluator.getAttributes(index: 0))
        XCTAssertNil(evaluator.getAttributes(index: 1))
        XCTAssertNil(evaluator.getAttributes(index: 2))
        XCTAssertNil(evaluator.getAttributes(index: 3))
    }

    func testMergedAttributes() {

        let splitName = "FACUNDO_TEST"
        let splitNames = [splitName]
        let evaluator = EvaluatorStub()

        let evalAttr: [String: Any] = ["ev1": 10.1,
                                       "ev2": "v1",
                                       "att2": false]

        attributesStorage.set(testAttributes(), forKey: userKey.matchingKey)

        let treatmentManager = createTreatmentManager(evaluator: evaluator)

        let _ = treatmentManager.getTreatment(splitName, key: userKey, attributes: evalAttr)
        let _ = treatmentManager.getTreatments(splits: splitNames, key: userKey, attributes: evalAttr)
        let _ = treatmentManager.getTreatmentWithConfig(splitName, key: userKey, attributes: evalAttr)
        let _ = treatmentManager.getTreatmentsWithConfig(splits: splitNames, key: userKey, attributes: evalAttr)

        for i in 0..<4 {
            let attr = evaluator.getAttributes(index: i)
            XCTAssertEqual(6, attr?.count)
            XCTAssertEqual("se1", attr?["att1"] as? String)
            XCTAssertEqual(false, attr?["att2"] as? Bool)
            XCTAssertEqual(1, attr?["att3"] as? Int)
            XCTAssertEqual(["a", "b", "c"], attr?["att4"] as? [String])
            XCTAssertEqual("v1", attr?["ev2"] as? String)
            XCTAssertEqual(10.1, attr?["ev1"] as? Double)
        }
    }

    func testOnlyStoredAttributes() {
        let splitName = "FACUNDO_TEST"
        let splitNames = [splitName]
        let evaluator = EvaluatorStub()
        attributesStorage.set(testAttributes(), forKey: userKey.matchingKey)

        let treatmentManager = createTreatmentManager(evaluator: evaluator)

        let _ = treatmentManager.getTreatment(splitName, key: userKey, attributes: nil)
        let _ = treatmentManager.getTreatments(splits: splitNames, key: userKey, attributes: nil)
        let _ = treatmentManager.getTreatmentWithConfig(splitName, key: userKey, attributes: nil)
        let _ = treatmentManager.getTreatmentsWithConfig(splits: splitNames, key: userKey, attributes: nil)

        for i in 0..<4 {
            let attr = evaluator.getAttributes(index: i)
            XCTAssertEqual(4, attr?.count)
            XCTAssertEqual("se1", attr?["att1"] as? String)
            XCTAssertEqual(true, attr?["att2"] as? Bool)
            XCTAssertEqual(1, attr?["att3"] as? Int)
            XCTAssertEqual(["a", "b", "c"], attr?["att4"] as? [String])
        }
    }

    func testRuntimeProducers() {
        let userKey = Key(matchingKey: "nico_test")
        let splitName = ""
        let splitNames: [String] = []

        let treatmentManager = createTreatmentManager()

        let _ = treatmentManager.getTreatment(splitName, key: userKey, attributes: nil)
        let _ = treatmentManager.getTreatments(splits: splitNames, key: userKey, attributes: nil)
        let _ = treatmentManager.getTreatmentWithConfig(splitName, key: userKey, attributes: nil)
        let _ = treatmentManager.getTreatmentsWithConfig(splits: splitNames, key: userKey, attributes: nil)

        XCTAssertEqual(1, telemetryProducer.methodLatencies[.treatment])
        XCTAssertEqual(1, telemetryProducer.methodLatencies[.treatments])
        XCTAssertEqual(1, telemetryProducer.methodLatencies[.treatmentWithConfig])
        XCTAssertEqual(1, telemetryProducer.methodLatencies[.treatmentsWithConfig])
    }
    
    func assertControl(splitList: [String], treatment: String, treatmentList: [String:String], splitResult: SplitResult?, splitResultList: [String:SplitResult]) {
        XCTAssertEqual(SplitConstants.control, treatment)
        
        XCTAssertEqual(SplitConstants.control, splitResult?.treatment)
        XCTAssertNil(splitResult?.config)
        
        for splitName in splitList {
            XCTAssertNotNil(treatmentList[splitName])
        }
        
        for res in splitResultList.values {
            XCTAssertEqual(SplitConstants.control, res.treatment)
        }
    }

    override func tearDown() {
    }
    
    func createTreatmentManager(evaluator: Evaluator? = nil) -> TreatmentManager {
        client = InternalSplitClientStub(splitsStorage: storageContainer.splitsStorage, mySegmentsStorage: storageContainer.mySegmentsStorage)
        let defaultEvaluator = evaluator ?? DefaultEvaluator(splitClient: client)

        let eventsManager = SplitEventsManagerMock()
        eventsManager.isSegmentsReadyFired = true
        eventsManager.isSplitsReadyFired = true
        eventsManager.isSegmentsReadyFromCacheFired = true
        eventsManager.isSplitsReadyFromCacheFired = true

        return DefaultTreatmentManager(evaluator: defaultEvaluator,
                                       splitConfig: SplitClientConfig(),
                                       eventsManager: eventsManager, impressionLogger: impressionsLogger,
                                       telemetryProducer: telemetryProducer, attributesStorage: attributesStorage,
                                       keyValidator: DefaultKeyValidator(),
                                       splitValidator: DefaultSplitValidator(splitsStorage: splitsStorage),
                                       validationLogger: validationLogger)
    }
    
    func loadSplitsFile() -> [Split] {
        return loadSplitFile(name: "splitchanges_1")
    }
    
    func loadSplitFile(name fileName: String) -> [Split] {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
           let change = try? Json.encodeFrom(json: file, to: SplitChange.self) {
            return change.splits
        }
        return [Split]()
    }

    func testAttributes() -> [String: Any] {
        return ["att1": "se1",
                "att2": true,
                "att3": 1,
                "att4": ["a", "b", "c"]]
    }
}
