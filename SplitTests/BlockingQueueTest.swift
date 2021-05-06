//
//  BlockingQueueTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 06/05/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class BlockingQueueTest: XCTestCase {

    override func setUp() {
    }

    func testAddAndTake() {
        let endExp = XCTestExpectation()
        var local = [SplitInternalEvent]()
        let globalQ = DispatchQueue.global()
        let queue = DefaultInternalEventBlockingQueue()

        globalQ.async {
            while true {
                let event = queue.take()
                local.append(event)
                if local.count == 4 {
                    endExp.fulfill()
                }
            }
        }
        globalQ.asyncAfter(deadline: .now() + 1) {
            queue.add(SplitInternalEvent.mySegmentsLoadedFromCache)
            globalQ.asyncAfter(deadline: .now() + 1) {
                queue.add(SplitInternalEvent.splitsLoadedFromCache)
            }
        }

        queue.add(SplitInternalEvent.splitsUpdated)
        queue.add(SplitInternalEvent.mySegmentsUpdated)
        wait(for: [endExp], timeout: 10)
        XCTAssertEqual(SplitInternalEvent.splitsUpdated, local[0])
        XCTAssertEqual(SplitInternalEvent.mySegmentsUpdated, local[1])
        XCTAssertEqual(SplitInternalEvent.mySegmentsLoadedFromCache, local[2])
        XCTAssertEqual(SplitInternalEvent.splitsLoadedFromCache, local[3])

    }

    override func tearDown() {
    }
}

