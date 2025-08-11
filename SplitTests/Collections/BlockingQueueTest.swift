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
        let globalQ = DispatchQueue.test
        let queue = DefaultInternalEventBlockingQueue()

        globalQ.async {
            while true {
                do {
                    let event = try queue.take()
                    local.append(event)
                    if local.count == 4 {
                        endExp.fulfill()
                    }
                } catch {
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

    func testInterrupt() {
        let endExp = XCTestExpectation()
        var local = [SplitInternalEvent]()
        let globalQ = DispatchQueue.global()
        let queue = DefaultInternalEventBlockingQueue()
        var interrupted = false

        globalQ.async {
            while true {
                do {
                    let event = try queue.take()
                    local.append(event)
                } catch {
                    endExp.fulfill()
                    interrupted = true
                }
            }
        }
        globalQ.asyncAfter(deadline: .now() + 1) {
            queue.add(SplitInternalEvent.mySegmentsLoadedFromCache)
            globalQ.asyncAfter(deadline: .now() + 1) {
                queue.stop()
            }
        }

        queue.add(SplitInternalEvent.splitsUpdated)
        queue.add(SplitInternalEvent.mySegmentsUpdated)

        wait(for: [endExp], timeout: 10)
        XCTAssertEqual(SplitInternalEvent.splitsUpdated, local[0])
        XCTAssertEqual(SplitInternalEvent.mySegmentsUpdated, local[1])
        XCTAssertEqual(SplitInternalEvent.mySegmentsLoadedFromCache, local[2])
        XCTAssertTrue(interrupted)
    }

    func stressAddAndTakeTest() {
        let endExp = XCTestExpectation()
        var local = [SplitInternalEvent]()
        let globalQ = DispatchQueue.global()
        let qu1 = DispatchQueue(label: "stress-test-take-q1", attributes: .concurrent)
        let qu2 = DispatchQueue(label: "stress-test-take-q2", attributes: .concurrent)
        let qu3 = DispatchQueue(label: "stress-test-take-q3", attributes: .concurrent)
        let qu4 = DispatchQueue(label: "stress-test-take-q4", attributes: .concurrent)
//        let qu5 = DispatchQueue(label: "stress-test-take-q4", attributes: .concurrent)

        let quA1 = DispatchQueue(label: "stress-test-take-qa1", attributes: .concurrent)
        let quA2 = DispatchQueue(label: "stress-test-take-qa2", attributes: .concurrent)
        let quA3 = DispatchQueue(label: "stress-test-take-qa3", attributes: .concurrent)

        let stopq = DispatchQueue(label: "stress-test-take-stop", attributes: .concurrent)
        let queue = DefaultInternalEventBlockingQueue()

        globalQ.async {
            for _ in 0..<50000 {
                do {
                    let event = try queue.take()
                    local.append(event)
                    print("Took: \(event)")
                } catch {
                }
            }

        }

        quA1.async {
            for _ in 0..<50000 {
                do {
                    let event = try queue.take()
                    local.append(event)
                    print("Took QA1: \(event)")
                } catch {
                    print("\n\n\nERROR!!!!: \(error) \n\n\n")
                }
            }
        }

        quA2.async {
            for _ in 0..<50000 {
                do {
                    let event = try queue.take()
                    local.append(event)
                    Thread.sleep(forTimeInterval: 0.3)
                    print("Took QA2: \(event)")
                } catch {
                }
            }
        }

        quA3.async {
            for _ in 0..<50000 {
                do {
                    Thread.sleep(forTimeInterval: 0.5)
                    let event = try queue.take()
                    local.append(event)
                    print("Took QA3: \(event)")
                } catch {
                }
            }
        }

        qu1.async {
            for _ in 1..<100000 {
                queue.add(SplitInternalEvent.splitsUpdated)
                print("qu1 add")
                Thread.sleep(forTimeInterval: 0.2)
            }
        }

        qu2.async {
            for _ in 1..<10000 {
                print("qu2 add")
                queue.add(SplitInternalEvent.sdkReadyTimeoutReached)
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        qu3.async {
            for _ in 1..<10000 {
                print("qu3 add")
                queue.add(SplitInternalEvent.splitsUpdated)
                Thread.sleep(forTimeInterval: 0.8)
            }
        }

        qu4.async {
            for _ in 1..<10000 {
                print("qu4 add")
                queue.add(SplitInternalEvent.mySegmentsUpdated)
                sleep(1)
            }
        }

        stopq.asyncAfter(deadline: .now() + 10) {
            print("\n\n\n\n\n\n**************** STOP 10 \n\n\n\n\n")
            queue.stop()
        }

        stopq.asyncAfter(deadline: .now() + 20) {
            print("\n\n\n\n\n\n**************** STOP 20 \n\n\n\n\n")
            queue.stop()
        }

        stopq.async {
            for i in 1..<10000 {
                Thread.sleep(forTimeInterval: 2)
                print("\n\n\n\n\n\n**************** STOP i=\(i) \n\n\n\n\n")
                queue.stop()
            }
        }

        wait(for: [endExp], timeout: 50)
    }

    func testCallingTakeOnEmptyQueueThrowsNoElementAvailable() {
        let endExp = XCTestExpectation()
        let queue = DefaultInternalEventBlockingQueue()

        do {
            _ = try queue.take()
        } catch BlockingQueueError.noElementAvailable {
            endExp.fulfill()
        } catch {
            XCTFail()
        }

        self.wait(for: [endExp], timeout: 1)
    }
}

