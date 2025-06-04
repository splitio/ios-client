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
    var flagSetsCache: FlagSetsCacheMock!
    var propertyValidator: PropertyValidatorStub!

    var validationLoggerStub: ValidationMessageLoggerStub {
        return validationLogger as! ValidationMessageLoggerStub
    }

    override func setUp() {

        impressionsLogger = ImpressionsLoggerStub()
        validationLogger = ValidationMessageLoggerStub()
        attributesStorage = DefaultAttributesStorage()
        telemetryProducer = TelemetryStorageStub()
        flagSetsCache = FlagSetsCacheMock()
        propertyValidator = PropertyValidatorStub()

        flagSetsCache.flagSets = ["set1": ["TEST_SETS_1"],
                                  "set2": ["TEST_SETS_1", "TEST_SETS_2"],
                                  "set3": ["TEST_SETS_2"],
                                  "set5": ["TEST_SETS_2"],
                                  "set10": ["TEST_SETS_3"],
                                  "set20": ["TEST_SETS_3"],
        ]

        if storageContainer == nil {
            let splits = loadSplitsFile()
            let mySegments = ["s1", "s2", "test_copy"]
            splitsStorage = SplitsStorageStub()
            _ = splitsStorage.update(splitChange: ProcessedSplitChange(activeSplits: splits,
                                                                       archivedSplits: [],
                                                                       changeNumber: -1, 
                                                                       updateTimestamp: 100))
            mySegmentsStorage = MySegmentsStorageStub()
            mySegmentsStorage.set(SegmentChange(segments: mySegments), forKey: "the_key")
            storageContainer = SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "pepe"),
                                                     splitsStorage: splitsStorage,
                                                     persistentSplitsStorage: PersistentSplitsStorageStub(),
                                                     impressionsStorage: ImpressionsStorageStub(),
                                                     persistentImpressionsStorage: PersistentImpressionsStorageStub(),
                                                     impressionsCountStorage: PersistentImpressionsCountStorageStub(),
                                                     eventsStorage: EventsStorageStub(),
                                                     persistentEventsStorage: PersistentEventsStorageStub(),
                                                     telemetryStorage: telemetryProducer,
                                                     mySegmentsStorage: mySegmentsStorage,
                                                     myLargeSegmentsStorage: mySegmentsStorage,
                                                     attributesStorage: attributesStorage,
                                                     uniqueKeyStorage: PersistentUniqueKeyStorageStub(), 
                                                     flagSetsCache: flagSetsCache,
                                                     persistentHashedImpressionsStorage: PersistentHashedImpressionStorageMock(),
                                                     hashedImpressionsStorage: HashedImpressionsStorageMock(),
                                                     generalInfoStorage: GeneralInfoStorageMock(),
                                                     ruleBasedSegmentsStorage: RuleBasedSegmentsStorageStub(),
                                                     persistentRuleBasedSegmentsStorage: PersistentRuleBasedSegmentsStorageStub())
        }
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
        XCTAssertEqual(1, telemetryProducer.methodLatencies[.treatmentWithConfig])
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
        let matchingKey = "the_key"
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

    func testBasicEvaluationsBySets() {
        let matchingKey = "the_key"
        let splitNames = ["TEST_SETS_1", "TEST_SETS_2", "TEST_SETS_3"]

        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        let res1 = treatmentManager.getTreatmentsByFlagSet(flagSet: "set1", attributes: nil)
        let res2 = treatmentManager.getTreatmentsByFlagSets(flagSets: ["set1", "set5"], attributes: nil)
        let res3 = treatmentManager.getTreatmentsWithConfigByFlagSet(flagSet: "set2", attributes: nil)
        let res4 = treatmentManager.getTreatmentsWithConfigByFlagSets(flagSets: ["set1", "set5", "set10"], attributes: nil)
        let res5 = treatmentManager.getTreatmentsWithConfigByFlagSets(flagSets: ["set100", "set500"], attributes: nil)


        let impressionsCount = impressionsLogger.impressionsPushedCount
        let imp1 = impressionsLogger.impressions[splitNames[0]]
        let imp2 = impressionsLogger.impressions[splitNames[1]]
        let imp3 = impressionsLogger.impressions[splitNames[2]]

        XCTAssertEqual("off1", res1[splitNames[0]])

        XCTAssertEqual("off1", res2[splitNames[0]])
        XCTAssertEqual("off2", res2[splitNames[1]])

        XCTAssertEqual("off1", res3[splitNames[0]]?.treatment)
        XCTAssertEqual("off2", res3[splitNames[1]]?.treatment)
        XCTAssertEqual("{\"f1\":\"v1\"}", res3[splitNames[1]]?.config)

        XCTAssertEqual("off1", res4[splitNames[0]]?.treatment)
        XCTAssertEqual("off2", res4[splitNames[1]]?.treatment)
        XCTAssertEqual("{\"f1\":\"v1\"}", res3[splitNames[1]]?.config)
        XCTAssertEqual("off3", res4[splitNames[2]]?.treatment)

        XCTAssertEqual(0, res5.count)

        XCTAssertEqual(8, impressionsCount)
        XCTAssertNotNil(imp1)
        XCTAssertNotNil(imp2)
        XCTAssertNotNil(imp3)

        XCTAssertEqual(0, telemetryProducer.methodLatencies[.treatment] ?? 0)
        XCTAssertEqual(0, telemetryProducer.methodLatencies[.treatments] ?? 0)
        XCTAssertEqual(0, telemetryProducer.methodLatencies[.treatmentWithConfig] ?? 0)
        XCTAssertEqual(0, telemetryProducer.methodLatencies[.treatmentsWithConfig] ?? 0)

        XCTAssertEqual(1, telemetryProducer.methodLatencies[.treatmentsByFlagSet])
        XCTAssertEqual(1, telemetryProducer.methodLatencies[.treatmentsByFlagSets])
        XCTAssertEqual(1, telemetryProducer.methodLatencies[.treatmentsWithConfigByFlagSet])
        XCTAssertEqual(2, telemetryProducer.methodLatencies[.treatmentsWithConfigByFlagSets])

    }

    func testNoStoredAttributes() {
        let userKey = "key"
        let splitName = "FACUNDO_TEST"
        let splitNames = [splitName]
        let evaluator = EvaluatorStub()

        let treatmentManager = createTreatmentManager(matchingKey: userKey, evaluator: evaluator)

        let _ = treatmentManager.getTreatment(splitName, attributes: nil)
        let _ = treatmentManager.getTreatments(splits: splitNames, attributes: nil)
        let _ = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil)
        let _ = treatmentManager.getTreatmentsWithConfig(splits: splitNames, attributes: nil)

        XCTAssertNil(evaluator.getAttributes(index: 0))
        XCTAssertNil(evaluator.getAttributes(index: 1))
        XCTAssertNil(evaluator.getAttributes(index: 2))
        XCTAssertNil(evaluator.getAttributes(index: 3))
    }

    func testMergedAttributes() {
        let userKey = "key"
        let splitName = "FACUNDO_TEST"
        let splitNames = [splitName]
        let evaluator = EvaluatorStub()

        let evalAttr: [String: Any] = ["ev1": 10.1,
                                       "ev2": "v1",
                                       "att2": false]

        attributesStorage.set(testAttributes(), forKey: userKey)

        let treatmentManager = createTreatmentManager(matchingKey: userKey, evaluator: evaluator)

        let _ = treatmentManager.getTreatment(splitName, attributes: evalAttr)
        let _ = treatmentManager.getTreatments(splits: splitNames, attributes: evalAttr)
        let _ = treatmentManager.getTreatmentWithConfig(splitName, attributes: evalAttr)
        let _ = treatmentManager.getTreatmentsWithConfig(splits: splitNames, attributes: evalAttr)

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
        let userKey = "key"
        let splitName = "FACUNDO_TEST"
        let splitNames = [splitName]
        let evaluator = EvaluatorStub()
        attributesStorage.set(testAttributes(), forKey: userKey)

        let treatmentManager = createTreatmentManager(matchingKey: userKey, evaluator: evaluator)

        let _ = treatmentManager.getTreatment(splitName, attributes: nil)
        let _ = treatmentManager.getTreatments(splits: splitNames, attributes: nil)
        let _ = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil)
        let _ = treatmentManager.getTreatmentsWithConfig(splits: splitNames, attributes: nil)

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
        let matchingKey = "nico_test"
        let splitName = ""
        let splitNames: [String] = []

        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)

        let _ = treatmentManager.getTreatment(splitName, attributes: nil)
        let _ = treatmentManager.getTreatments(splits: splitNames, attributes: nil)
        let _ = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil)
        let _ = treatmentManager.getTreatmentsWithConfig(splits: splitNames, attributes: nil)

        XCTAssertEqual(1, telemetryProducer.methodLatencies[.treatment])
        XCTAssertEqual(1, telemetryProducer.methodLatencies[.treatments])
        XCTAssertEqual(1, telemetryProducer.methodLatencies[.treatmentWithConfig])
        XCTAssertEqual(1, telemetryProducer.methodLatencies[.treatmentsWithConfig])
    }

    func testEvaluationWithProperties() {
        let matchingKey = "the_key"
        let splitName = "FACUNDO_TEST"
        let properties = ["key1": "value1", "key2": 123, "key3": true] as [String: Any]
        let evaluationOptions = EvaluationOptions(properties: properties)

        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        _ = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil, evaluationOptions: evaluationOptions)
        let impression = impressionsLogger.impressions[splitName]

        XCTAssertNotNil(impression)
        XCTAssertNotNil(impression?.properties)

        if let propertiesJson = impression?.properties, let data = propertiesJson.data(using: .utf8) {
            do {
                let deserializedProperties = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                XCTAssertNotNil(deserializedProperties)
                XCTAssertEqual(deserializedProperties?["key1"] as? String, "value1")
                XCTAssertEqual(deserializedProperties?["key2"] as? Int, 123)
                XCTAssertEqual(deserializedProperties?["key3"] as? Bool, true)
            } catch {
                XCTFail("Failed to deserialize properties JSON: \(error)")
            }
        } else {
            XCTFail("Properties JSON is nil or invalid")
        }
    }

    func testEvaluationWithEmptyProperties() {
        let matchingKey = "the_key"
        let splitName = "FACUNDO_TEST"
        let emptyProperties = [String: Any]()
        let evaluationOptions = EvaluationOptions(properties: emptyProperties)

        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        _ = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil, evaluationOptions: evaluationOptions)
        let impression = impressionsLogger.impressions[splitName]

        XCTAssertNotNil(impression)
        XCTAssertNil(impression?.properties, "Empty properties should result in nil properties in the impression")
    }

    func testEvaluationWithNilProperties() {
        let matchingKey = "the_key"
        let splitName = "FACUNDO_TEST"
        let evaluationOptions = EvaluationOptions(properties: nil)

        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        _ = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil, evaluationOptions: evaluationOptions)
        let impression = impressionsLogger.impressions[splitName]

        XCTAssertNotNil(impression)
        XCTAssertNil(impression?.properties, "Nil properties should result in nil properties in the impression")
    }

    func testPropertiesAreSentToValidator() {
        let matchingKey = "the_key"
        let splitName = "Test_Save_1"
        
        let treatmentManager = createTreatmentManager(matchingKey: matchingKey)
        
        let properties: [String: Any] = [
            "string": "test",
            "number": 123,
            "boolean": true
        ]
        
        let evaluationOptions = EvaluationOptions(properties: properties)
        
        propertyValidator.validateCalled = false
        propertyValidator.lastPropertiesValidated = nil
        
        _ = treatmentManager.getTreatmentWithConfig(splitName, attributes: nil, evaluationOptions: evaluationOptions)
        
        XCTAssertTrue(propertyValidator.validateCalled, "PropertyValidator.validate() should be called")
        XCTAssertNotNil(propertyValidator.lastPropertiesValidated, "Properties should be passed to the validator")
        
        if let validatedProps = propertyValidator.lastPropertiesValidated {
            XCTAssertEqual(validatedProps["string"] as? String, "test")
            XCTAssertEqual(validatedProps["number"] as? Int, 123)
            XCTAssertEqual(validatedProps["boolean"] as? Bool, true)
        }
        
        let impression = impressionsLogger.impressions[splitName]
        XCTAssertNotNil(impression, "Impression should be logged")
        XCTAssertNotNil(impression?.properties, "Properties should be included in the impression")
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

    func createTreatmentManager(matchingKey: String, bucketingKey: String? = nil, evaluator: Evaluator? = nil) -> DefaultTreatmentManager {
        let key = Key(matchingKey: matchingKey, bucketingKey: bucketingKey)
        client = InternalSplitClientStub(splitsStorage: storageContainer.splitsStorage, 
                                         mySegmentsStorage: storageContainer.mySegmentsStorage,
                                         myLargeSegmentsStorage: storageContainer.mySegmentsStorage)
        let defaultEvaluator = evaluator ?? DefaultEvaluator(splitsStorage: storageContainer.splitsStorage,
                                                             mySegmentsStorage: storageContainer.mySegmentsStorage,
                                                             myLargeSegmentsStorage: storageContainer.myLargeSegmentsStorage)

        let eventsManager = SplitEventsManagerMock()
        eventsManager.isSegmentsReadyFired = true
        eventsManager.isSplitsReadyFired = true
        eventsManager.isSegmentsReadyFromCacheFired = true
        eventsManager.isSplitsReadyFromCacheFired = true

        let flagSetsValidator = FlagSetsValidatorMock()
        flagSetsValidator.validateOnEvaluatioResults = ["set1", "set2", "set3", "set5", "set10", "set20"]

        return DefaultTreatmentManager(evaluator: defaultEvaluator,
                                       key: key, splitConfig: SplitClientConfig(),
                                       eventsManager: eventsManager, impressionLogger: impressionsLogger,
                                       telemetryProducer: telemetryProducer,
                                       storageContainer: storageContainer,
                                       flagSetsValidator: flagSetsValidator,
                                       keyValidator: DefaultKeyValidator(),
                                       splitValidator: DefaultSplitValidator(splitsStorage: splitsStorage),
                                       validationLogger: validationLogger,
                                       propertyValidator: propertyValidator)
    }

    func loadSplitsFile() -> [Split] {
        return loadSplitFile(name: "splitchanges_1")
    }

    func loadSplitFile(name fileName: String) -> [Split] {
        if let file = FileHelper.readDataFromFile(sourceClass: self, name: fileName, type: "json"),
           let change = try? Json.decodeFrom(json: file, to: TargetingRulesChange.self) {
            return change.featureFlags.splits
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
