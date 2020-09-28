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
    var impressionsManager: ImpressionsManager!
    var splitFetcher: SplitFetcher!
    var mySegmentsFetcher: MySegmentsFetcher!
    var splitCache: SplitCacheProtocol!
    var client: InternalSplitClient!
    
    var impressionsManagerStub: ImpressionsManagerStub {
        return impressionsManager as! ImpressionsManagerStub
    }
    
    var validationLoggerStub: ValidationMessageLoggerStub {
        return validationLogger as! ValidationMessageLoggerStub
    }
    
    
    override func setUp() {
        
        impressionsManager = ImpressionsManagerStub()
        validationLogger = ValidationMessageLoggerStub()
        if splitFetcher == nil {
            let splits = loadSplitsFile()
            let mySegments = ["s1", "s2", "test_copy"]
            splitCache = SplitCacheStub(splits: splits, changeNumber: -1)
            splitFetcher = SplitFetcherStub(splits: splits)
            mySegmentsFetcher = MySegmentsFetcherStub(mySegments: mySegments)
        }
    }
    
    override func tearDown() {
    }
    
    func testBasicEvaluationNoConfig() {
        let matchingKey = "the_key"
        let splitName = "FACUNDO_TEST"
        
        
        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil)
        let impression = impressionsManagerStub.impressions[splitName]
        
        
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
        let impression = impressionsManagerStub.impressions[splitName]
        
        
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
        let splitName = "Test"
        
        
        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        let splitResult = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil)
        let impression = impressionsManagerStub.impressions[splitName]
        
        
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
        let splitNames = ["FACUNDO_TEST", "testo2222", "Test"]
        
        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        let splitResults = treatmentManager.getTreatmentsWithConfig(splits: splitNames, attributes: nil)
        
        let r1 = splitResults["FACUNDO_TEST"]
        let r2 = splitResults["testo2222"]
        let r3 = splitResults["Test"]
        
        let impressionsCount = impressionsManagerStub.impressions.count
        let imp1 = impressionsManagerStub.impressions[splitNames[0]]
        let imp2 = impressionsManagerStub.impressions[splitNames[1]]
        let imp3 = impressionsManagerStub.impressions[splitNames[2]]
        
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
        
        
        XCTAssertEqual(0, impressionsManagerStub.impressions.count)
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
        
        
        XCTAssertEqual(0, impressionsManagerStub.impressions.count)
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
        
        
        XCTAssertEqual(0, impressionsManagerStub.impressions.count)
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
        
        XCTAssertEqual(0, impressionsManagerStub.impressions.count)
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
        client = InternalSplitClientStub(splitFetcher: splitFetcher, mySegmentsFetcher: mySegmentsFetcher)
        let evaluator = DefaultEvaluator(splitClient: client)

        let eventsManager = SplitEventsManagerMock()
        eventsManager.isSegmentsReadyFired = true
        eventsManager.isSplitsReadyFired = true
        return DefaultTreatmentManager(evaluator: evaluator, key: key, splitConfig: SplitClientConfig(), eventsManager: eventsManager, impressionsManager: impressionsManager, metricsManager: DefaultMetricsManager.shared, keyValidator: DefaultKeyValidator(), splitValidator: DefaultSplitValidator(splitCache: splitCache), validationLogger: validationLogger)
    }
    
    func loadSplitsFile() -> [Split] {
        return loadSplitFile(name: "splitchanges_1")
    }
    
    func loadSplitFile(name fileName: String) -> [Split] {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
            let change = try? Json.encodeFrom(json: file, to: SplitChange.self),
            let splits = change.splits {
            return splits
        }
        return [Split]()
    }
}
