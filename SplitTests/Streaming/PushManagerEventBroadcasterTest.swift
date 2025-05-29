//
//  PushManagerEventBroadcasterTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 28/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class PushManagerEventBroadcasterTest: XCTestCase {
    var channel: SyncEventBroadcaster!
    override func setUp() {
        channel = DefaultSyncEventBroadcaster()
    }

    func testRegister() {
        // Test that all registered handler
        // receives the message
        let exp1 = XCTestExpectation(description: "exp1")
        let exp2 = XCTestExpectation(description: "exp2")
        let exp3 = XCTestExpectation(description: "exp3")
        var e1: SyncStatusEvent?
        var e2: SyncStatusEvent?
        var e3: SyncStatusEvent?

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

        DispatchQueue.test.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            self.channel.push(event: .pushSubsystemDown)
        }
        wait(for: [exp1, exp2, exp3], timeout: 5.0)

        XCTAssertEqual(.pushSubsystemDown, e1)
        XCTAssertEqual(.pushSubsystemDown, e2)
        XCTAssertEqual(.pushSubsystemDown, e3)
    }

    func testStop() {
        // Test that no handler receives event
        // after channel is stopped
        let exp1 = XCTestExpectation(description: "exp1")

        var count = 0

        channel.register(handler: { event in
            count += 1
        })

        DispatchQueue.test.asyncAfter(deadline: DispatchTime.now() + 0.2) {
            self.channel.push(event: .pushSubsystemDown)
        }

        DispatchQueue.test.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.channel.destroy()
        }

        DispatchQueue.test.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            self.channel.push(event: .pushSubsystemDown)
            exp1.fulfill()
        }

        wait(for: [exp1], timeout: 5.0)

        XCTAssertEqual(1, count)
    }

    override func tearDown() {}
}
