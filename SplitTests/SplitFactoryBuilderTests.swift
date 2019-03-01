//
//  SplitFactoryBuilderTests.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 31/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import XCTest
@testable import Split

class SplitFactoryBuilderTests: XCTestCase {

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
        let builder: SplitFactoryBuilder = DefaultSplitFactoryBuilder()
        let factory = builder
            .setApiKey("pepe")
            .setMatchingKey("pepe")
            .build()
        XCTAssertNotNil(factory, "Factory should not be nil")
    }

    func testKey() {
        let builder: SplitFactoryBuilder = DefaultSplitFactoryBuilder()
        let factory = builder
            .setApiKey("pepe")
            .setKey(Key(matchingKey: "pepe"))
            .build()
        XCTAssertNotNil(factory, "Factory should not be nil")
    }

}
