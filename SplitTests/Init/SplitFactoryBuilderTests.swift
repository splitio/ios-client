//
//  SplitFactoryBuilderTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 31/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

@testable import Split
import XCTest

class SplitFactoryBuilderTests: XCTestCase {
    private let moreThanOneFactoryMessage = """
    You already have an instance of the Split factory. Make sure you definitely want this
        additional instance. We recommend keeping only one instance of the factory at all times
        (Singleton pattern) and reusing it throughout your application.
    """

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNullValues() {
        let builder: SplitFactoryBuilder = DefaultSplitFactoryBuilder()
        let factory = builder.build()
        XCTAssertNil(factory, "Factory should be nil")
    }

    func testNullApiKey() {
        let builder: SplitFactoryBuilder = DefaultSplitFactoryBuilder()
        let factory = builder.setMatchingKey("pepe").build()
        XCTAssertNil(factory, "Factory should be nil")
    }

    func testEmptyApiKey() {
        let builder: SplitFactoryBuilder = DefaultSplitFactoryBuilder()
        let factory = builder.setApiKey(" ").setMatchingKey("pepe").build()
        XCTAssertNil(factory, "Factory should be nil")
    }

    func testNullMatchingKey() {
        let builder: SplitFactoryBuilder = DefaultSplitFactoryBuilder()
        let factory = builder.setApiKey("pepe").build()
        XCTAssertNil(factory, "Factory should be nil")
    }

    func testLongMatchingKey() {
        let key = String(repeating: "k", count: ValidationConfig.default.maximumKeyLength + 1)
        let builder: SplitFactoryBuilder = DefaultSplitFactoryBuilder()
        let factory = builder
            .setApiKey("pepe")
            .setMatchingKey(key)
            .build()
        XCTAssertNil(factory, "Factory should be nil")
    }

    func testLongBucketingKey() {
        let bkey = String(repeating: "k", count: ValidationConfig.default.maximumKeyLength + 1)
        let builder: SplitFactoryBuilder = DefaultSplitFactoryBuilder()
        let factory = builder
            .setApiKey("pepe")
            .setMatchingKey("key")
            .setBucketingKey(bkey)
            .build()
        XCTAssertNil(factory, "Factory should be nil")
    }

    func testNullKey() {
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "pepe1"))
        let factory = builder
            .setApiKey("pepe")
            .setMatchingKey("pepe")
            .build()
        XCTAssertNotNil(factory, "Factory should not be nil")
    }

    func testKey() {
        let builder = DefaultSplitFactoryBuilder()
        _ = builder.setTestDatabase(TestingHelper.createTestDatabase(name: "pepe1"))
        let factory = builder
            .setApiKey("pepe")
            .setKey(Key(matchingKey: "pepe"))
            .build()
        XCTAssertNotNil(factory, "Factory should not be nil")
    }

    func testMultiFactorySameKey() {
        let builder1 = DefaultSplitFactoryBuilder()
        let builder2 = DefaultSplitFactoryBuilder()

        _ = builder1.setTestDatabase(TestingHelper.createTestDatabase(name: "pepe1"))
        _ = builder2.setTestDatabase(TestingHelper.createTestDatabase(name: "pepe2"))

        let logger = ValidationMessageLoggerStub()
        builder2.validationLogger = logger

        // we should maintain this unused references
        // to be able to test the factory registry.
        // Otherwise weak references on it will be nil
        // and the test will fail
        let f1 = builder1
            .setApiKey("pepe")
            .setKey(Key(matchingKey: "pepe"))
            .build()

        let f2 = builder2
            .setApiKey("pepe")
            .setKey(Key(matchingKey: "pepe"))
            .build()

        print("print \(f1!.version) - \(f2!.version)")

        XCTAssertEqual(factoryValidationMessage(count: 1, for: "pepe"), logger.messages[0])
    }

    func testMultiFactoryTwoSameKey() {
        let builder1 = DefaultSplitFactoryBuilder()
        let builder2 = DefaultSplitFactoryBuilder()

        _ = builder1.setTestDatabase(TestingHelper.createTestDatabase(name: "pepe1"))
        _ = builder2.setTestDatabase(TestingHelper.createTestDatabase(name: "pepe2"))

        let logger = ValidationMessageLoggerStub()
        builder2.validationLogger = logger

        let f1 = builder1
            .setApiKey("pepe")
            .setKey(Key(matchingKey: "pepe"))
            .build()

        let f2 = builder1
            .setApiKey("pepe")
            .setKey(Key(matchingKey: "pepe"))
            .build()

        let f3 = builder2
            .setApiKey("pepe")
            .setKey(Key(matchingKey: "pepe"))
            .build()

        print("print \(f1!.version) - \(f2!.version) - \(f3!.version)")

        XCTAssertEqual(factoryValidationMessage(count: 2, for: "pepe"), logger.messages[0])
    }

    func testMultiFactoryDifferentKey() {
        let builder1 = DefaultSplitFactoryBuilder()
        let builder2 = DefaultSplitFactoryBuilder()

        _ = builder1.setTestDatabase(TestingHelper.createTestDatabase(name: "pepe1"))
        _ = builder2.setTestDatabase(TestingHelper.createTestDatabase(name: "pepe2"))

        let logger = ValidationMessageLoggerStub()
        builder2.validationLogger = logger

        let f1 = builder1
            .setApiKey("pepe1")
            .setKey(Key(matchingKey: "pepe"))
            .build()

        let f2 = builder2
            .setApiKey("pepe")
            .setKey(Key(matchingKey: "pepe"))
            .build()

        print("print \(f1!.version) - \(f2!.version)")

        XCTAssertEqual(moreThanOneFactoryMessage, logger.messages[0])
    }

    func factoryValidationMessage(count: Int, for key: String) -> String {
        let m =
            "You already have \(count) \(count == 1 ? "factory" : "factories") with this API Key. We recommend keeping only one instance of the factory at all times (Singleton pattern) and reusing it throughout your application."
        return m
    }
}
