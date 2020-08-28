//
//  PushManagerEventBroadcasterTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 28/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class PushManagerEventBroadcasterTest: XCTestCase {

    var channel: PushManagerEventBroadcaster!
    override func setUp() {
        channel = DefaultPushManagerEventBroadcaster()
    }

    func testRegister() {
        // Test that all registered handler
        // receives the message
        let exp1 = XCTestExpectation(description: "exp1")
        let exp2 = XCTestExpectation(description: "exp2")
        let exp3 = XCTestExpectation(description: "exp3")
        var e1: PushStatusEvent?
        var e2: PushStatusEvent?
        var e3: PushStatusEvent?

        channel.register(handler: { event in
            e1 = event
            exp1.fulfill()
        })

        channel.register(handler: { event in
            e2 = event
            exp2.fulfill()
        })

        channel.register(handler: { event in
            e3 = event
            exp3.fulfill()
        })

        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1.0) {
            self.channel.push(event: .enablePolling)
        }
        wait(for: [exp1, exp2, exp3], timeout: 5.0)

        XCTAssertEqual(.enablePolling, e1)
        XCTAssertEqual(.enablePolling, e2)
        XCTAssertEqual(.enablePolling, e3)

    }

    func testStop() {
        // Test that no handler receives event
        // after channel is stopped
        let exp1 = XCTestExpectation(description: "exp1")

        var count = 0

        channel.register(handler: { event in
            count+=1
        })

        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.2) {
            self.channel.push(event: .enablePolling)
        }

        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.channel.stop()
        }

        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1.0) {
            self.channel.push(event: .enablePolling)
            exp1.fulfill()
        }

        wait(for: [exp1], timeout: 5.0)

        XCTAssertEqual(1, count)

    }

    override func tearDown() {

    }
}
