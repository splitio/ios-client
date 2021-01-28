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
    
    var impressionsLogger: ImpressionsLoggerStub!
    
    var validationLoggerStub: ValidationMessageLoggerStub {
        return validationLogger as! ValidationMessageLoggerStub
    }
    
    
    override func setUp() {
        
        impressionsLogger = ImpressionsLoggerStub()
        validationLogger = ValidationMessageLoggerStub()
        if storageContainer == nil {
            let splits = loadSplitsFile()
            let mySegments = ["s1", "s2", "test_copy"]
            splitsStorage = SplitsStorageStub()
            splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: splits, archivedSplits: [],
                                                                   changeNumber: -1, updateTimestamp: 100))
            mySegmentsStorage = MySegmentsStorageStub()
            mySegmentsStorage.set(mySegments)
            storageContainer = SplitStorageContainer(fileStorage: FileStorageStub(),
                                                     splitsStorage: splitsStorage,
                                                     mySegmentsStorage: mySegmentsStorage,
                                                     impressionsStorage: PersistentImpressionsStorageStub())
        }
    }
    
    override func tearDown() {
    }
    
    func testBasicEvaluationNoConfig() {
        let matchingKey = "the_key"
        let splitName = "FACUNDO_TEST"
        
        
        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil)
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
    }
    
    func testBasicEvaluationWithConfig() {
        let matchingKey = "the_key"
        let splitName = "Test_Save_1"
        
        
        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil)
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
        let matchingKey = "the_key"
        let splitName = "OldTest"
        
        
        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil)
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
        let matchingKey = "thekey"
        let splitNames = ["FACUNDO_TEST", "testo2222", "OldTest"]
        
        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        let splitResults = treatmentManager.getTreatmentsWithConfig(splits: splitNames, attributes: nil)
        
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
        let matchingKey = "nico_test"
        let splitName = "NON_EXISTING_1"
        let splitNames = ["NON_EXISTING_1", "NON_EXISTING_2", "NON_EXISTING_3"]
        
        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        
        let treatment = treatmentManager.getTreatment(splitName, attributes: nil)
        let treatmentList = treatmentManager.getTreatments(splits: splitNames, attributes: nil)
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil)
        let splitResults = treatmentManager.getTreatmentsWithConfig(splits: splitNames, attributes: nil)
        
        
        XCTAssertEqual(0, impressionsLogger.impressions.count)
        assertControl(splitList: splitNames, treatment: treatment, treatmentList: treatmentList, splitResult: splitResult, splitResultList: splitResults)
        
        XCTAssertFalse(validationLoggerStub.hasError)
        XCTAssertTrue(validationLoggerStub.hasWarnings)
        
    }
    
    func testEmptySplits() {
        let matchingKey = "nico_test"
        let splitName = ""
        let splitNames: [String] = []
        
        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        
        let treatment = treatmentManager.getTreatment(splitName, attributes: nil)
        let treatmentList = treatmentManager.getTreatments(splits: splitNames, attributes: nil)
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil)
        let splitResults = treatmentManager.getTreatmentsWithConfig(splits: splitNames, attributes: nil)
        
        
        XCTAssertEqual(0, impressionsLogger.impressions.count)
        assertControl(splitList: splitNames, treatment: treatment, treatmentList: treatmentList, splitResult: splitResult, splitResultList: splitResults)
        XCTAssertTrue(validationLoggerStub.hasError)
        XCTAssertFalse(validationLoggerStub.hasWarnings)
    }
    
    func testEmptyKey() {
        let matchingKey = ""
        let splitName = "FACUNDO_TEST"
        let splitNames = ["FACUNDO_TEST", "a_new_split_2", "benchmark_jw_1"]
        
        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        
        let treatment = treatmentManager.getTreatment(splitName, attributes: nil)
        let treatmentList = treatmentManager.getTreatments(splits: splitNames, attributes: nil)
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil)
        let splitResults = treatmentManager.getTreatmentsWithConfig(splits: splitNames, attributes: nil)
        
        
        XCTAssertEqual(0, impressionsLogger.impressions.count)
        assertControl(splitList: splitNames, treatment: treatment, treatmentList: treatmentList, splitResult: splitResult, splitResultList: splitResults)
        XCTAssertTrue(validationLoggerStub.hasError)
        XCTAssertFalse(validationLoggerStub.hasWarnings)
    }
    
    func testLongKey() {
        let matchingKey = String(repeating: "p", count: 251)
        let splitName = "FACUNDO_TEST"
        let splitNames = ["FACUNDO_TEST", "a_new_split_2", "benchmark_jw_1"]
        
        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        
        let treatment = treatmentManager.getTreatment(splitName, attributes: nil)
        let treatmentList = treatmentManager.getTreatments(splits: splitNames, attributes: nil)
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil)
        let splitResults = treatmentManager.getTreatmentsWithConfig(splits: splitNames, attributes: nil)
        
        XCTAssertEqual(0, impressionsLogger.impressions.count)
        assertControl(splitList: splitNames, treatment: treatment, treatmentList: treatmentList, splitResult: splitResult, splitResultList: splitResults)
        XCTAssertTrue(validationLoggerStub.hasError)
        XCTAssertFalse(validationLoggerStub.hasWarnings)
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
    
    func createTreatmentManager(matchingKey: String, bucketingKey: String? = nil) -> TreatmentManager {
        let key = Key(matchingKey: matchingKey, bucketingKey: bucketingKey)
        client = InternalSplitClientStub(splitsStorage: storageContainer.splitsStorage, mySegmentsStorage: storageContainer.mySegmentsStorage)
        let evaluator = DefaultEvaluator(splitClient: client)

        let eventsManager = SplitEventsManagerMock()
        eventsManager.isSegmentsReadyFired = true
        eventsManager.isSplitsReadyFired = true
        return DefaultTreatmentManager(evaluator: evaluator, key: key, splitConfig: SplitClientConfig(),
                                       eventsManager: eventsManager, impressionLogger: impressionsLogger,
                                       metricsManager: DefaultMetricsManager.shared, keyValidator: DefaultKeyValidator(),
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
}
