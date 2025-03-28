//
//  PropertyValidatorTest.swift
//  SplitTests
//
//  Created on 2025-03-27.
//  Copyright 2025 Split. All rights reserved.
//

import XCTest
@testable import Split

class PropertyValidatorTest: XCTestCase {
    
    func testPropertiesPassedToValidator() {
        // Create a property validator mock
        let propertyValidatorMock = PropertyValidatorMock()
        
        // Create a treatment manager with the mock validator
        let treatmentManager = DefaultTreatmentManager(
            evaluator: EvaluatorStub(),
            key: Key(matchingKey: "test_key"),
            splitConfig: SplitClientConfig(),
            eventsManager: SplitEventsManagerMock(),
            impressionLogger: ImpressionsLoggerStub(),
            telemetryProducer: TelemetryStorageStub(),
            storageContainer: SplitStorageContainerStub(),
            flagSetsValidator: FlagSetsValidatorMock(),
            keyValidator: DefaultKeyValidator(),
            splitValidator: SplitValidatorStub(),
            validationLogger: ValidationMessageLoggerStub(),
            propertyValidator: propertyValidatorMock
        )
        
        // Create simple properties
        let properties: [String: Any] = [
            "string": "test",
            "number": 123,
            "boolean": true
        ]
        
        // Create evaluation options with properties
        let evaluationOptions = EvaluationOptions(properties: properties)
        
        // Call getTreatment with properties
        _ = treatmentManager.getTreatment("test_split", attributes: nil, evaluationOptions: evaluationOptions)
        
        // Verify that the validator was called with the correct properties
        XCTAssertTrue(propertyValidatorMock.validationWasCalled, "PropertyValidator.validate() should be called")
        XCTAssertNotNil(propertyValidatorMock.lastValidatedProperties, "Properties should be passed to the validator")
        
        // Check that the properties match
        if let validatedProps = propertyValidatorMock.lastValidatedProperties {
            XCTAssertEqual(validatedProps["string"] as? String, "test")
            XCTAssertEqual(validatedProps["number"] as? Int, 123)
            XCTAssertEqual(validatedProps["boolean"] as? Bool, true)
        }
    }
}

// Mock classes needed for the test
class PropertyValidatorMock: PropertyValidator {
    var lastValidatedProperties: [String: Any]?
    var validationWasCalled = false
    
    func validate(properties: [String: Any]?, initialSizeInBytes: Int, validationTag: String) -> PropertyValidationResult {
        validationWasCalled = true
        lastValidatedProperties = properties
        return PropertyValidationResult.valid(properties: properties, sizeInBytes: initialSizeInBytes)
    }
}

class EvaluatorStub: Evaluator {
    func evaluate(key: Key, bucketingKey: String?, splitName: String, attributes: [String: Any]?) -> EvaluationResult {
        return EvaluationResult.control(label: "control")
    }
}

class SplitEventsManagerMock: SplitEventsManager {
    var isSegmentsReadyFired = true
    var isSplitsReadyFired = true
    var isSegmentsReadyFromCacheFired = true
    var isSplitsReadyFromCacheFired = true
    
    func notifyInternalEvent(event: SplitInternalEvent) {}
    func register(event: SplitEvent, task: SplitEventTask) {}
    func notifyEvent(event: SplitEvent) {}
    func eventAlreadyTriggered(event: SplitEvent) -> Bool { return true }
    func start() {}
    func stop() {}
}

class SplitStorageContainerStub: SplitStorageContainer {
    var splitsStorage: SplitsStorage = SplitsStorageStub()
    var mySegmentsStorage: MySegmentsStorage = MySegmentsStorageStub()
    var myLargeSegmentsStorage: MySegmentsStorage = MySegmentsStorageStub()
    var eventsStorage: EventsStorage = EventsStorageStub()
    var impressionsStorage: ImpressionsStorage = ImpressionsStorageStub()
    var telemetryStorage: TelemetryStorage = TelemetryStorageStub()
    var uniqueKeysStorage: UniqueKeysStorage = UniqueKeysStorageStub()
    var attributesStorage: AttributesStorage = AttributesStorageStub()
    var generalInfoStorage: GeneralInfoStorage = GeneralInfoStorageStub()
    var flagSetsStorage: FlagSetsStorage = FlagSetsStorageStub()
    var hashedImpressionsStorage: HashedImpressionsStorage = HashedImpressionsStorageStub()
    var impressionsCountStorage: ImpressionsCountStorage = ImpressionsCountStorageStub()
}

class SplitValidatorStub: SplitValidator {
    func validate(splitName: String) -> ValidationErrorInfo {
        return ValidationErrorInfo()
    }
}

class UniqueKeysStorageStub: UniqueKeysStorage {
    func getUniqueKeys() -> [UniqueKey] { return [] }
    func push(uniqueKey: UniqueKey) {}
    func clear() {}
    func delete(forKey: String) {}
}

class FlagSetsStorageStub: FlagSetsStorage {
    func update(flagSets: [String: [String]]) -> Int { return 0 }
    func getAll() -> [String: [String]] { return [:] }
    func getFlagSets(forFeatureFlag: String) -> [String] { return [] }
    func getFeatureFlags(forFlagSets: [String]) -> [String] { return [] }
    func clear() {}
}

class HashedImpressionsStorageStub: HashedImpressionsStorage {
    func push(hashed: HashedImpressions) {}
    func popAll() -> [HashedImpressions] { return [] }
    func clear() {}
}

class ImpressionsCountStorageStub: ImpressionsCountStorage {
    func push(count: ImpressionsCount) {}
    func popAll() -> [ImpressionsCount] { return [] }
    func clear() {}
}

class GeneralInfoStorageStub: GeneralInfoStorage {
    func set(info: GeneralInfo) {}
    func get() -> GeneralInfo? { return nil }
    func update(info: GeneralInfo) {}
    func clear() {}
}

class AttributesStorageStub: AttributesStorage {
    func getAll(forKey: String) -> [String: Any]? { return nil }
    func set(forKey: String, attributes: [String: Any]?) -> Bool { return true }
    func remove(forKey: String, attributeName: String) -> Bool { return true }
    func clear(forKey: String) -> Bool { return true }
    func getGlobal() -> [String: Any]? { return nil }
    func setGlobal(attributes: [String: Any]?) -> Bool { return true }
    func removeGlobal(attributeName: String) -> Bool { return true }
    func clearGlobal() -> Bool { return true }
}

class EventsStorageStub: EventsStorage {
    func push(event: EventDTO) {}
    func popAll() -> [EventDTO] { return [] }
    func popNWithMetadata(n: Int) -> EventsHit { return EventsHit(events: [], metadata: nil) }
    func clear() {}
    func setMaxAccumulatedSize(size: Int64) {}
    func getMaxAccumulatedSize() -> Int64 { return 0 }
    func getAccumulatedSize() -> Int64 { return 0 }
}

class ImpressionsStorageStub: ImpressionsStorage {
    func push(impression: KeyImpression) {}
    func popAll() -> [KeyImpression] { return [] }
    func popNWithMetadata(n: Int) -> ImpressionsHit { return ImpressionsHit(impressions: [], metadata: nil) }
    func clear() {}
    func setMaxAccumulatedSize(size: Int64) {}
    func getMaxAccumulatedSize() -> Int64 { return 0 }
    func getAccumulatedSize() -> Int64 { return 0 }
}

class MySegmentsStorageStub: MySegmentsStorage {
    func getAll(forKey: String) -> [String] { return [] }
    func set(segments: [String], forKey: String) {}
    func clear() {}
    func isInSegments(name: String, forKey: String) -> Bool { return false }
}

class SplitsStorageStub: SplitsStorage {
    func getAll() -> [Split] { return [] }
    func getAllSplits() -> [String: Split] { return [:] }
    func update(splitChange: ProcessedSplitChange) -> Bool { return true }
    func getSplit(name: String) -> Split? { return nil }
    func getSplits(names: [String]) -> [String: Split] { return [:] }
    func getTreatment(name: String) -> String? { return nil }
    func changeNumber() -> Int64 { return 0 }
    func clear() {}
    func getNamesByFlagSets(flagSets: [String]) -> [String] { return [] }
}

class FlagSetsValidatorMock: FlagSetsValidator {
    var validateOnEvaluatioResults: [String] = []
    
    func validateOnEvaluation(flagSets: [String]) -> [String] {
        return validateOnEvaluatioResults
    }
}
