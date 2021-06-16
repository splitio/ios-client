//
//  ImpresionsObserverTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 16/06/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class ImpressionsObserverTest: XCTestCase {

    override func setUp() {
    }

    func testBasicFunctionality() {
        let observer = ImpressionsObserver(size: 5)
        let impression = Impression()
        impression.keyName = "someKey"
        impression.feature = "someFeature"
        impression.treatment = "on"
        impression.time = Date().unixTimestamp()
        impression.label = "in segment all"
        impression.changeNumber = 1234


        // Add 5 new impressions so that the old one is evicted and re-try the test.
        for imp in generateImpressions(count: 5) {
            _ = observer.testAndSet(impression: imp)
        }
        XCTAssertNil(observer.testAndSet(impression: impression))
        XCTAssertEqual(observer.testAndSet(impression: impression), impression.time)
    }

    func testConcurrencyVsAccuracy() throws {
        let observer = ImpressionsObserver(size: 5000)
        let impressions = SynchronizedArrayWrapper<Impression>()


        let operationQueue = OperationQueue()
        for _ in 0..<5 {
            operationQueue.addOperation {
                self.caller(observer: observer, count: 1000, impressions: impressions)
            }
        }
        operationQueue.waitUntilAllOperationsAreFinished()

        XCTAssertEqual(5000, impressions.count)
        for imp in impressions.all {
            XCTAssertTrue(imp.previousTime == nil || imp.previousTime ?? 0 <= imp.time ?? -1)
        }
    }

    func caller(observer: ImpressionsObserver, count: Int, impressions: SynchronizedArrayWrapper<Impression> ) {

        for _ in 0..<count {
            let impression = Impression()
            impression.keyName = "key_\(Int.random(in: 1..<100))"
            impression.feature = "feature_\(Int.random(in: 1..<10))"
            impression.treatment =  Bool.random() ? "on" : "off"
            impression.label = "label_\(Int.random(in: 1..<5))"
            impression.changeNumber = 1234567
            impression.time = Date().unixTimestamp()
            impression.previousTime = observer.testAndSet(impression: impression)
            impressions.append(impression)
        }
    }

    func generateImpressions(count: Int) -> [Impression] {
        var impressions = [Impression]()
        for i in 0..<count {
            let impression = Impression()
            impression.keyName = "key_\(i)"
            impression.feature = "feature_\(i)"
            impression.treatment = (i % 2 == 0 ? "on" : "off")
            impression.label = (i % 2 == 0 ? "in segment all" : "whitelisted")
            impression.changeNumber = Int64(i * i)
            impression.time = Date().unixTimestamp()
            impressions.append(impression)
        }
        return impressions
    }
}

