//
//  CertificatePinningConfigTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 04/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class CertificatePinningConfigTests: XCTestCase {
    let bundle: Bundle = .init(for: CertificatePinningConfigTests.self)
    var builder: CertificatePinningConfig.Builder!
    let testHost = "www.superhost.com"

    override func setUp() {
        Logger.shared.level = .verbose
        builder = CertificatePinningConfig.Builder()
        builder.bundle = bundle
    }

    func testAddWrongCertificate() {
        var msg = ""
        builder.addPin(host: testHost, certificateName: "wrong_cert")
        do {
            _ = try builder.build()
        } catch {
            msg = error.localizedDescription
        }

        XCTAssertTrue(msg.contains("Couldn't get SPKI from"))
    }

    func testAddWrongSpkiCertificate() {
        var msg = ""
        builder.addPin(host: testHost, certificateName: "ed25519-cert")
        do {
            _ = try builder.build()
        } catch {
            msg = error.localizedDescription
        }

        XCTAssertTrue(msg.contains("Couldn't get SPKI from"))
    }

    func testAddWrongStringHashFormatHash() {
        var msg = ""
        builder.addPin(host: testHost, keyHash: "wrong")
        do {
            _ = try builder.build()
        } catch {
            msg = error.localizedDescription
        }

        XCTAssertTrue(msg.contains("Unable to add pin for host"))
    }

    func testAddWrongStringHashType() {
        var msg = ""
        builder.addPin(host: testHost, keyHash: "sha1111/hashahahahahahah")
        do {
            _ = try builder.build()
        } catch {
            msg = error.localizedDescription
        }

        XCTAssertTrue(msg.contains("Key hash algorithm not supported for pin"))
    }

    func testAddWrongStringHash() {
        var msg = ""
        builder.addPin(host: testHost, keyHash: "sha256/")
        do {
            _ = try builder.build()
        } catch {
            msg = error.localizedDescription
        }
        XCTAssertEqual(msg, "Key hash is empty for host \(testHost) algorithm: sha256")
    }

    func testAddCertificateAndHashes() {
        builder.addPin(host: "host1", certificateName: "rsa_2048_cert.pem") // It's a der file
        builder.addPin(host: "host2", keyHash: "sha1/xISLOKMMW9KyAtns62UziyEEOylkAH1T5k0G5ARhmSg=")
        builder.addPin(host: "host3", certificateName: "rsa_4096_cert.pem") // It's a der file
        builder.addPin(host: "host4", keyHash: "sha1/atdIXmiD1M7qqMdQauqERJiaPrypufzeAxGHGSVqwMI=")
        builder.addPin(host: "host5", keyHash: "sha256/atdIXmiD1M7qqMdQauqERJiaPrypufzeAxGHGSVqwMI=")
        guard let config = try? builder.build() else {
            XCTFail()
            return
        }
        let pins = config.pins

        XCTAssertEqual(5, pins.count)
        XCTAssertEqual(2, pins.filter { $0.algo == .sha1 }.count)
        XCTAssertEqual(3, pins.filter { $0.algo == .sha256 }.count)

        for i in 1 ..< 5 {
            XCTAssertEqual(pins[i - 1].host, "host\(i)")
        }
    }
}
