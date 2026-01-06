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

class PushManagerEventBroadcasterTest: XCTestCase, @unchecked Sendable {

    var channel: SyncEventBroadcaster!
    override func setUp() {
        channel = DefaultSyncEventBroadcaster()
    }
    
    // Event 1
    let lock = DispatchQueue(label: "lock1")
    var e1: SyncStatusEvent?
    func setE1(_ val: SyncStatusEvent) { lock.sync { e1 = val } }
    
    // Event 2
    let lock2 = DispatchQueue(label: "lock2")
    var e2: SyncStatusEvent?
    func setE2(_ val: SyncStatusEvent) { lock.sync { e2 = val } }
    
    // Event 3
    let lock3 = DispatchQueue(label: "lock3")
    var e3: SyncStatusEvent?
    func setE3(_ val: SyncStatusEvent) { lock.sync { e3 = val } }

    func testRegister() {
        // Test that all registered handler
        // receives the message
        let exp1 = XCTestExpectation(description: "exp1")
        let exp2 = XCTestExpectation(description: "exp2")
        let exp3 = XCTestExpectation(description: "exp3")

        channel.register(handler: { event in
            self.e1 = event
            exp1.fulfill()
        })

        channel.register(handler: { event in
            self.e2 = event
            exp2.fulfill()
        })

        channel.register(handler: { event in
            self.e3 = event
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
    
    let lockCount = DispatchQueue(label: "lock")
    var count = 0
    func countSet(_ val: Int) {
        lockCount.sync { count = val }
    }
    func countGet() -> Int {
        lockCount.sync { count }
    }

    func testStop() {
        // Test that no handler receives event
        // after channel is stopped
        let exp1 = XCTestExpectation(description: "exp1")

        channel.register(handler: { event in
            self.count+=1
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
