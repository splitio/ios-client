//
//  SslPinningValidatorTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 12/06/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
import Security
import XCTest
@testable import Split

class TlsPinningValidatorTests: XCTestCase {

    var validator: TlsPinValidator!
    let secHelper = SecurityHelper()

    override func setUp() {
        validator = DefaultTlsPinValidator()
        Logger.shared.level = .verbose
    }

    func testEc256r1Spki() {
        publicKeyExtractionTest(certName: "ec_256v1_cert",
                                pubKeyName: "ec_256v1_pub",
                                keyType: CertKeyType.secp256r1, debug: true)
    }

    func testEc384r1Spki() {
        publicKeyExtractionTest(certName: "ec_secp384r1_cert",
                                pubKeyName: "ec_secp384r1_pub",
                                keyType: CertKeyType.secp384r1, debug: true)
    }

    func testEc521r1Spki() {
        publicKeyExtractionTest(certName: "ec_secp521r1_cert",
                                pubKeyName: "ec_secp521r1_pub",
                                keyType: CertKeyType.secp521r1, debug: true)
    }

    func testAppleEcSpki() {
        publicKeyExtractionTest(certName: "developer.apple.com_ecpk",
                                pubKeyName: "ec_apple_public_key",
                                keyType: CertKeyType.secp256r1, debug: true)
    }

    func testRsa2048Spki() {
        publicKeyExtractionTest(certName: "rsa_2048_cert.pem",
                                pubKeyName: "rsa_2048_pub",
                                keyType: CertKeyType.rsa2048, debug: true)
    }

    func testRsa3072Spki() {
        publicKeyExtractionTest(certName: "rsa_3072_cert.pem",
                                pubKeyName: "rsa_3072_pub",
                                keyType: CertKeyType.rsa3072, debug: true)
    }

    func testRsa4096Spki() {
        publicKeyExtractionTest(certName: "rsa_4096_cert.pem", 
                                pubKeyName: "rsa_4096_pub",
                                keyType: CertKeyType.rsa4096, debug: true)
    }


    let validHost = "developer.apple.com"
    let validCertName = "developer.apple.com_ecpk"
    let validKeyName =  "ec_apple_public_key"
    func testPinnedValidCertificateSha256() {

        let algo = KeyHashAlgo.sha256
        let expectedHash = secHelper.hashedKey(keyName: validKeyName, algo: algo)
        let pins = [CredentialPin(host: validHost, hash: expectedHash, algo: algo)]

        pinValidationTest(host: validHost, certName: validCertName,
                          algo: algo, pins: pins, expectedResult: .success)

    }

    func testPinnedValidCertificateSha1() {

        let algo = KeyHashAlgo.sha1
        let expectedHash = secHelper.hashedKey(keyName: validKeyName, algo: algo)
        let pins = [CredentialPin(host: validHost, hash: expectedHash, algo: algo)]

        pinValidationTest(host: validHost, certName: validCertName,
                          algo: algo, pins: pins, expectedResult: .success)

    }

    func testUnPinnedValidCertificate() {

        let algo = KeyHashAlgo.sha256
        let expectedHash = secHelper.hashedKey(keyName: "rsa_4096_pub", algo: algo)
        let pins = [CredentialPin(host: validHost, hash: expectedHash, algo: algo)]

        pinValidationTest(host: validHost, certName: validCertName,
                          algo: algo, pins: pins, expectedResult: .credentialNotPinned)

    }

    func testUntrustedCertificate() {

        let algo = KeyHashAlgo.sha256
        let expectedHash = secHelper.hashedKey(keyName: "rsa_4096_pub", algo: algo)
        let pins = [CredentialPin(host: validHost, hash: expectedHash, algo: algo)]

        pinValidationTest(host: validHost, certName: "rsa_4096_cert.pem",
                          algo: algo, pins: pins, expectedResult: .invalidChain)

    }

    func testInvalidChallengeMethod() {

        let credential = secHelper.createInvalidChallenge(
            authMethod: NSURLAuthenticationMethodClientCertificate)
        let res = validator.validate(credential: credential,
                                      pins: [CredentialPin(host: validHost, hash: Data(), algo: .sha256)])
        
        XCTAssertEqual(CredentialValidationResult.noServerTrustMethod, res)
    }

    func testInvalidChallengeNoSecTrust() {

        let credential = secHelper.createInvalidChallenge(
            authMethod: NSURLAuthenticationMethodServerTrust)
        let res = validator.validate(credential: credential,
                                      pins: [CredentialPin(host: validHost, hash: Data(), algo: .sha256)])

        XCTAssertEqual(CredentialValidationResult.unavailableServerTrust, res)
    }

    func testValidationParameter() {

        let res = validator.validate(credential: [String: String]() as AnyObject,
                                      pins: [CredentialPin(host: validHost, hash: Data(), algo: .sha256)])

        XCTAssertEqual(CredentialValidationResult.invalidParameter, res)
    }

    func pinValidationTest(host: String,
                           certName: String,
                           algo: KeyHashAlgo,
                           pins: [CredentialPin],
                           expectedResult: CredentialValidationResult) {


        guard let challenge = secHelper.createAuthChallenge(host: host, certName: certName) else {
            Logger.d("Could not create sec trust for certificate pinning test certificate \(certName)")
            XCTFail()
            return
        }

        let result = validator.validate(credential: challenge, pins: pins)
        
        XCTAssertEqual(expectedResult, result)
    }

    func publicKeyExtractionTest(certName: String, pubKeyName: String, keyType: CertKeyType, debug: Bool = false) {
        let keyData = FileHelper.loadFileData(sourceClass:self, name: pubKeyName, type: "der")

        if debug {
            print("LOADED PUB KEY ---------------")
            print(keyData?.hexadecimalRepresentation ?? "NO KEY DATA")
            print("------------------------------")
        }

        let loadedData = FileHelper.loadFileData(sourceClass:self, name: certName, type: "der")!
        guard let cerData = loadedData as? NSData else {
            print("Could not load certificate \(certName) for name")
            XCTFail()
            return
        }

        let cert = SecCertificateCreateWithData(nil, cerData)

        var extractedKey: CertSpki?
        if let cert = cert {
            // Casting to validate this implementation in particular
            extractedKey  = (validator as! DefaultTlsPinValidator).spki(from: cert)
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

class SecurityHelper  {
    private let limit: UInt8 = 10 // "\n"
    func loadPemData(name: String, type: String = "pem") -> Data? {
        guard let pem = FileHelper.loadFileData(sourceClass: self, name: name, type: type) else {
            Logger.e("Error loading pem file: \(name)")
            return nil
        }

        let pemBase64 = pem
            .split(separator: limit)

        let final = Array(pemBase64
            .dropFirst()
            .dropLast()
            .joined())

        print("PEM DEC")
        print(Base64Utils.decodeBase64(Data(final).stringRepresentation)?.hexadecimalRepresentation)
        print("PEM DEC FIN")

        return  Data(final)

    }

    func inspect(certificate: SecCertificate) {
        print("Certificate summary:")
        print(SecCertificateCopySubjectSummary(certificate) as? String)
        print(String(repeating: "-", count: 50))
    }

    func createProtectionSpace(host: String, certName: String) -> URLProtectionSpace? {
        guard let serverTrust = createServerTrust(certName: certName) else {
            return nil
        }
        return ProtectionSpaceMock(host: host, secTrust: serverTrust)
    }

    func createServerTrust(certName: String) -> SecTrust? {

        guard let certificate = certificateFromFile(name: certName) else {
            return nil
        }

        var trust: SecTrust?
        SecTrustCreateWithCertificates(certificate, SecPolicyCreateBasicX509(), &trust)
        return trust
    }

    func certificateFromFile(name: String) -> SecCertificate? {

        let loadedData = FileHelper.loadFileData(sourceClass:self, name: name, type: "der")!
        guard let cerData = loadedData as? NSData else {
            print("Could not load certificate \(name) for name")
            return nil
        }

        return SecCertificateCreateWithData(nil, cerData)
    }

    func createAuthChallenge(host: String, certName: String) -> URLAuthenticationChallenge? {

        guard let protectionSpace = createProtectionSpace(host: host, certName: certName) else {
            Logger.d("Could not create protection space mock")
            return nil
        }

        // Create a mock URLAuthenticationChallenge
        return URLAuthenticationChallenge(
            protectionSpace: protectionSpace,
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: ChallengeSenderMock()
        )
    }

    func createInvalidChallenge(authMethod: String) -> URLAuthenticationChallenge {
        return URLAuthenticationChallenge(
            protectionSpace: ProtectionSpaceMock(authMethod: authMethod),
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: ChallengeSenderMock()
        )
    }

    func createInvalidChallengeWithoutSecTrust() -> URLAuthenticationChallenge {
        return URLAuthenticationChallenge(
            protectionSpace: ProtectionSpaceMock(authMethod: NSURLAuthenticationMethodServerTrust),
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: ChallengeSenderMock()
        )
    }

    func hashedKey(keyName: String, algo: KeyHashAlgo) -> Data {
        guard let keyData = FileHelper.loadFileData(sourceClass:self, name: keyName, type: "der") else {
            Logger.d("Could not create key for certificate pinning test key \(keyName)")
            XCTFail()
            return Data()
        }

        guard let expectedHash = AlgoHelper.computeHash(keyData, algo: algo) else {
            Logger.d("Could not create key for certificate pinning test key \(keyName)")
            XCTFail()
            return Data()
        }

        return expectedHash
    }

}

class ChallengeSenderMock: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
    func cancel(_ challenge: URLAuthenticationChallenge) {}
}

class ProtectionSpaceMock: URLProtectionSpace {

    var serverTrustMock: SecTrust?
    init(host: String, secTrust: SecTrust) {
        self.serverTrustMock = secTrust
        super.init(host: host, port: 443,
                   protocol: NSURLProtectionSpaceHTTPS,
                   realm: nil,
                   authenticationMethod: NSURLAuthenticationMethodServerTrust)

    }

    init(host: String = "www.testhost.com",
         authProtocol: String = NSURLProtectionSpaceHTTPS,
         authMethod: String = NSURLAuthenticationMethodServerTrust) {

        super.init(host: host, port: 443,
                   protocol: authProtocol,
                   realm: nil,
                   authenticationMethod: authMethod)

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var serverTrust: SecTrust? {
        return serverTrustMock
    }
}
