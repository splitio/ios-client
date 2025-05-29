//
//  SslPinningValidatorTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 12/06/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
import Security
@testable import Split
import XCTest

class TlsPinningCheckerTests: XCTestCase {
    var validator: TlsPinChecker!
    let secHelper = SecurityHelper()
    let validHost = "developer.apple.com"
    let validCertName = "developer.apple.com_ecpk"
    let validKeyName = "ec_apple_public_key"

    override func setUp() {
        let pins = [CredentialPin(host: validHost, hash: Data(), algo: .sha256)]
        validator = DefaultTlsPinChecker(pins: pins)
        Logger.shared.level = .verbose
    }

    func testEc256r1Spki() {
        publicKeyExtractionTest(
            certName: "ec_256v1_cert",
            pubKeyName: "ec_256v1_pub",
            keyType: CertKeyType.secp256r1,
            debug: true)
    }

    func testEc384r1Spki() {
        publicKeyExtractionTest(
            certName: "ec_secp384r1_cert",
            pubKeyName: "ec_secp384r1_pub",
            keyType: CertKeyType.secp384r1,
            debug: true)
    }

    func testEc521r1Spki() {
        publicKeyExtractionTest(
            certName: "ec_secp521r1_cert",
            pubKeyName: "ec_secp521r1_pub",
            keyType: CertKeyType.secp521r1,
            debug: true)
    }

    func testAppleEcSpki() {
        publicKeyExtractionTest(
            certName: "developer.apple.com_ecpk",
            pubKeyName: "ec_apple_public_key",
            keyType: CertKeyType.secp256r1,
            debug: true)
    }

    func testRsa2048Spki() {
        publicKeyExtractionTest(
            certName: "rsa_2048_cert.pem",
            pubKeyName: "rsa_2048_pub",
            keyType: CertKeyType.rsa2048,
            debug: true)
    }

    func testRsa3072Spki() {
        publicKeyExtractionTest(
            certName: "rsa_3072_cert.pem",
            pubKeyName: "rsa_3072_pub",
            keyType: CertKeyType.rsa3072,
            debug: true)
    }

    func testRsa4096Spki() {
        publicKeyExtractionTest(
            certName: "rsa_4096_cert.pem",
            pubKeyName: "rsa_4096_pub",
            keyType: CertKeyType.rsa4096,
            debug: true)
    }

    func testUntrustedCertificate() {
        let algo = KeyHashAlgo.sha256
        let expectedHash = secHelper.hashedKey(keyName: "rsa_4096_pub", algo: algo)
        let pins = [CredentialPin(host: validHost, hash: expectedHash, algo: algo)]

        pinValidationTest(
            host: validHost,
            certName: "rsa_4096_cert.pem",
            algo: algo,
            pins: pins,
            expectedResult: .invalidChain)
    }

    func testInvalidChallengeMethod() {
        let credential = secHelper.createInvalidChallenge(
            authMethod: NSURLAuthenticationMethodClientCertificate)
        let res = validator.check(credential: credential)

        XCTAssertEqual(CredentialValidationResult.noServerTrustMethod, res)
    }

    func testInvalidChallengeNoSecTrust() {
        let credential = secHelper.createInvalidChallenge(
            authMethod: NSURLAuthenticationMethodServerTrust)
        let res = validator.check(credential: credential)
        XCTAssertEqual(CredentialValidationResult.unavailableServerTrust, res)
    }

    func testValidationParameter() {
        let res = validator.check(credential: [String: String]() as AnyObject)
        XCTAssertEqual(CredentialValidationResult.invalidParameter, res)
    }

    func pinValidationTest(
        host: String,
        certName: String,
        algo: KeyHashAlgo,
        pins: [CredentialPin],
        expectedResult: CredentialValidationResult) {
        guard let challenge = secHelper.createAuthChallenge(host: host, certName: certName) else {
            Logger.d("Could not create sec trust for certificate pinning test certificate \(certName)")
            XCTFail()
            return
        }

        validator = DefaultTlsPinChecker(pins: pins)

        let result = validator.check(credential: challenge)

        XCTAssertEqual(expectedResult, result)
    }

    func publicKeyExtractionTest(certName: String, pubKeyName: String, keyType: CertKeyType, debug: Bool = false) {
        let keyData = FileHelper.loadFileData(sourceClass: self, name: pubKeyName, type: "der")

        if debug {
            print("LOADED PUB KEY ---------------")
            print(keyData?.hexadecimalRepresentation ?? "NO KEY DATA")
            print("------------------------------")
        }

        let loadedData = FileHelper.loadFileData(sourceClass: self, name: certName, type: "der")!
        guard let cerData = loadedData as? NSData else {
            print("Could not load certificate \(certName) for name")
            XCTFail()
            return
        }

        let cert = SecCertificateCreateWithData(nil, cerData)

        var extractedKey: CertSpki?
        if let cert = cert {
            // Casting to validate this implementation in particular
            extractedKey = TlsCertificateParser.spki(from: cert)
            if debug {
                secHelper.inspect(certificate: cert)
                print("EXTRACTED PUB KEY ------------")
                print(extractedKey?.data.hexadecimalRepresentation ?? "NO EXT KEY DATA")
                print("------------------------------")
            }
        }

        XCTAssertEqual(keyType, extractedKey?.type)
        XCTAssertEqual(keyData, extractedKey?.data)
    }
}
