//
//  SslPinningValidatorTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 12/06/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class TlsPinningValidatorTests: XCTestCase {

    let validator = DefaultTlsPinValidator()
    override func setUp() {
        Logger.shared.level = .verbose
    }

    func testWhat() {
        //        let keyData = SecurityHelper().loadPemData(name:"apple_public_key")
        let keyData = FileHelper.loadFileData(sourceClass:self, name:"ec_apple_public_key", type: "der")

        print("------------------")
        print(keyData?.hexadecimalRepresentation ?? "NO KEY DATA")
        print(" PERM------------------")

        //        let cerDataPem = SecurityHelper().loadPemData(name:"developer.apple.com_ecpk", type: "cer")
        //        print(cerDataPem?.hexadecimalRepresentation ?? "NO CER DATA")

        let cerData = FileHelper.loadFileData(sourceClass:self, name:"developer.apple.com_ecpk", type: "der") as! NSData
        print("DER ------------------")
        //        print((cerData as Data?)?.hexadecimalRepresentation ?? "NO CER DATA")
        let cert = SecCertificateCreateWithData(nil, cerData)

        if let cert = cert {
            let extKey  = validator.spki(from: cert)
            print("ext key: \(extKey)")
        }

        XCTAssertNil(keyData)

        XCTAssertNil(cerData)
    }

    func testEc256k1_() {

        let keyData = FileHelper.loadFileData(sourceClass:self, name:"ec_secp384r1_pub", type: "der")

        print("------------------")
        print(keyData?.hexadecimalRepresentation ?? "NO KEY DATA")
        print(" PERM------------------")

        //        let cerDataPem = SecurityHelper().loadPemData(name:"developer.apple.com_ecpk", type: "cer")
        //        print(cerDataPem?.hexadecimalRepresentation ?? "NO CER DATA")

        let cerData = FileHelper.loadFileData(sourceClass:self, name:"ec_secp384r1_cert", type: "der") as! NSData
        print("DER ------------------")
        //        print((cerData as Data?)?.hexadecimalRepresentation ?? "NO CER DATA")
        let cert = SecCertificateCreateWithData(nil, cerData)

        if let cert = cert {
            let extKey  = validator.spki(from: cert)
            print("ext key: \(extKey)")
        }

        XCTAssertNil(keyData)

        XCTAssertNil(cerData)
    }

    func testEc256k1() {
        publicKeyExtractionTest(certName: "ec_secp256k1_cert", pubKeyName: "ec_secp256k1_pub", debug: true)
    }

    func testEc384r1() {
        publicKeyExtractionTest(certName: "ec_secp384r1_cert", pubKeyName: "ec_secp384r1_pub", debug: true)
    }

    func testEc521r1() {
        publicKeyExtractionTest(certName: "ec_secp521r1_cert", pubKeyName: "ec_secp521r1_pub", debug: true)
    }

    func testAppleEc() {
        publicKeyExtractionTest(certName: "developer.apple.com_ecpk", pubKeyName: "ec_apple_public_key", debug: true)
    }

    func testRsa2048() {
        publicKeyExtractionTest(certName: "rsa_2048_cert.pem", pubKeyName: "rsa_2048_pub", debug: true)
    }

    func testRsa3072() {
        publicKeyExtractionTest(certName: "rsa_3072_cert.pem", pubKeyName: "rsa_3072_pub", debug: true)
    }

    func testRsa4096() {
        publicKeyExtractionTest(certName: "rsa_4096_cert.pem", pubKeyName: "rsa_4096_pub", debug: true)
    }

    func testEd25519() {
        publicKeyExtractionTest(certName: "ed25519-cert", pubKeyName: "ed25519-pub", debug: true)

        _ = SecurityHelper().loadPemData(name: "ed25519-cert")
    }

    func publicKeyExtractionTest(certName: String, pubKeyName: String, debug: Bool = false) {

        let keyData = FileHelper.loadFileData(sourceClass:self, name: pubKeyName, type: "der")

        if debug {
            print("LOADED PUB KEY ---------------")
            print(keyData?.hexadecimalRepresentation ?? "NO KEY DATA")
            print("------------------------------")
        }

        let loadedData = FileHelper.loadFileData(sourceClass:self, name: certName, type: "der")!
        let cerData = loadedData as! NSData

//        print("CER DATA ------------------------------")
//        print(loadedData.hexadecimalRepresentation)
//        print("---------------")

        let cert = SecCertificateCreateWithData(nil, cerData)

        if let cert = cert {
            let extKey  = validator.spki(from: cert)

            print("EXTRACTED PUB KEY ------------")
            print(extKey?.data.hexadecimalRepresentation ?? "NO EXT KEY DATA")
            print("------------------------------")
        }

        XCTAssertNil(keyData)

        XCTAssertNil(cerData)
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
}
