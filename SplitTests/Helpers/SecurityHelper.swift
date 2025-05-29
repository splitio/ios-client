//
//  SecurityHelper.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 16/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
@testable import Split

class SecurityHelper {
    private let limit: UInt8 = 10 // "\n"
    func loadPemData(name: String, type: String = "pem") -> Data? {
        guard let pem = FileHelper.loadFileData(sourceClass: self, name: name, type: type) else {
            Logger.e("Error loading pem file: \(name)")
            return nil
        }

        let pemBase64 = pem
            .split(separator: limit)

        let final = Array(
            pemBase64
                .dropFirst()
                .dropLast()
                .joined())

        print("PEM DEC")
        print(Base64Utils.decodeBase64(Data(final).stringRepresentation)?.hexadecimalRepresentation)
        print("PEM DEC FIN")

        return Data(final)
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
        let loadedData = FileHelper.loadFileData(sourceClass: self, name: name, type: "der")!
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
            sender: ChallengeSenderMock())
    }

    func createInvalidChallenge(authMethod: String) -> URLAuthenticationChallenge {
        return URLAuthenticationChallenge(
            protectionSpace: ProtectionSpaceMock(authMethod: authMethod),
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: ChallengeSenderMock())
    }

    func createInvalidChallengeWithoutSecTrust() -> URLAuthenticationChallenge {
        return URLAuthenticationChallenge(
            protectionSpace: ProtectionSpaceMock(authMethod: NSURLAuthenticationMethodServerTrust),
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: ChallengeSenderMock())
    }

    func hashedKey(keyName: String, algo: KeyHashAlgo) -> Data {
        guard let keyData = FileHelper.loadFileData(sourceClass: self, name: keyName, type: "der") else {
            Logger.d("Could not create key for certificate pinning test key \(keyName)")
            return Data()
        }

        let expectedHash = AlgoHelper.computeHash(keyData, algo: algo)
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
        super.init(
            host: host,
            port: 443,
            protocol: NSURLProtectionSpaceHTTPS,
            realm: nil,
            authenticationMethod: NSURLAuthenticationMethodServerTrust)
    }

    init(
        host: String = "www.testhost.com",
        authProtocol: String = NSURLProtectionSpaceHTTPS,
        authMethod: String = NSURLAuthenticationMethodServerTrust) {
        super.init(
            host: host,
            port: 443,
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
