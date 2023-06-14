//
//  SseConnectionHandlerTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 13/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class SseConnectionHandlerTest: XCTestCase {

    override func setUp() {
    }

    func testConnectionStress() {
        let count = 10000
        let sseClientFactory = SseClientFactoryStub()
        let handler = SseConnectionHandler(sseClientFactory: sseClientFactory)
        let exp = XCTestExpectation()
        for _ in 1..<count {
            let client = SseClientMock(connected: true)
            client.results = [true, true]
            client.disconnectDelay = 10.0
            sseClientFactory.clients.append(client)
        }

        DispatchQueue.global().async {
            for _ in 1..<count {
                Thread.sleep(forTimeInterval: 0.2)
                print("go conn")
                handler.connect(jwt: JwtToken(issuedAt: 1, expirationTime: 1, channels: [], rawToken: ""), channels: []) { _ in print("conn ")
                }
            }
        }

        DispatchQueue(label: "split-q", attributes: .concurrent).async {
            for _ in 1..<count {
                print("discoo 1")
                Thread.sleep(forTimeInterval: 0.5)
                handler.disconnect()
            }
            exp.fulfill()
        }

        DispatchQueue(label: "split-qr", attributes: .concurrent).async {
            for _ in 1..<count {
                print("discoo 22")
                Thread.sleep(forTimeInterval: 0.3)
                handler.disconnect()
            }
        }

        DispatchQueue(label: "split-qr2", attributes: .concurrent).async {
            for _ in 1..<count {
                print("discoo 33")
                Thread.sleep(forTimeInterval: 0.7)
                handler.disconnect()
            }
        }
        wait(for: [exp], timeout: 120.0)

    }

    override func tearDown() {
    }
}

