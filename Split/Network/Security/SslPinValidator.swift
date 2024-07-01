//
//  SslPinValidator.swift
//  Split
//
//  Created by Javier Avrudsky on 05/06/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
import CommonCrypto

enum PinType {
    case key
    case certificate
}

struct CredentialPin {
    let host: String
    let hash: Data
    let algo: KeyHashAlgo
}

enum CredentialValidationResult {
    case success
    case error
    case noPinsForDomain
    case invalidChain
    case invalidCertificate
    case spkiError
    case noServerTrustMethod
    case noServerTrust
    case invalidCredential
    case invalidParameter
}

enum KeyHashAlgo {
    case sha256
    case sha1
}

struct CertKeyTypeHelper {
    private static let keyMapping: [String: CertKeyType] = [
        "\(kSecAttrKeyTypeRSA)_2048": .rsa2048,
        "\(kSecAttrKeyTypeRSA)_3072": .rsa3072,
        "\(kSecAttrKeyTypeRSA)_4096": .rsa4096,
        "\(kSecAttrKeyTypeEC)_256": .secp256r1,
        "\(kSecAttrKeyTypeEC)_348": .secp384r1,
        "\(kSecAttrKeyTypeEC)_521": .secp521r1
        ]

    static func map(type: String, size: Int) -> CertKeyType {
        if let type = keyMapping["\(type)_\(size)"] {
            return type
        }
        return .unsupported
    }
}

enum CertKeyType {
    case rsa2048
    case rsa3072
    case rsa4096
    case secp256r1 // aka NIST P-256
    case secp384r1 // aka NIST P-384
    case secp521r1 // aka NIST P-521
    case ed25519
    case unsupported

    static func from(type: String, size: Int) -> CertKeyType {
        return CertKeyTypeHelper.map(type: type, size: size)
    }

    func isSupported() -> Bool {
        switch self {
        case .rsa2048, .rsa3072, .rsa4096:
            return true
        case .secp256r1, .secp384r1, .secp521r1:
            return true
        default:
            return false
        }
    }
}



struct CertSpki {
    let type: CertKeyType
    var data: Data {
        return rawData
    }

    private var rawData: Data
    var hash: Data?

    init(type: CertKeyType, data: Data) {
        self.type = type
        self.rawData = data
    }

    mutating func addHeader(_ header: Data) {
        rawData = header + rawData
    }

    mutating func addHeader(_ header: [UInt8]) {
        rawData = Data(header) + rawData
    }
}

protocol TlsPinValidator {
    func validate(credential: AnyObject) -> CredentialValidationResult
}

struct DefaultTlsPinValidator {
    let pins = [CredentialPin]()

    // Using a generic parameter to aisolate Apple's framework and
    // also to make the component easily mockable
    func validate(credential: AnyObject) -> CredentialValidationResult {

        guard let challenge = credential as? URLAuthenticationChallenge else {
            Logger.e("The credential received is not a URLAuthenticationChallenge")
            return .invalidParameter
        }

        // Checking that the authentication method is server trust
        // and that the host is pinned to validation
        let protectionSpace = challenge.protectionSpace
        if protectionSpace.authenticationMethod != NSURLAuthenticationMethodServerTrust {
            logValidationAvoidance(host: protectionSpace.host,
                                   method: protectionSpace.authenticationMethod,
                                   message: "No server trust")
            //completionHandler(.performDefaultHandling, nil)
            return .noServerTrustMethod
        }

        if protectionSpace.authenticationMethod != NSURLAuthenticationMethodServerTrust {
            logValidationAvoidance(host: protectionSpace.host,
                                   method: protectionSpace.authenticationMethod,
                                   message: "Host not pinned")
            // completionHandler(.performDefaultHandling, nil)
            return .noServerTrustMethod
        }

        guard let serverTrust = protectionSpace.serverTrust else {
            logValidationAvoidance(host: protectionSpace.host,
                                   method: protectionSpace.authenticationMethod,
                                   message: "No server trust info")
            //completionHandler(.performDefaultHandling, nil)
            return .noServerTrust
        }

        if checkValidity(of: serverTrust, protectionSpace: protectionSpace) != .success {
            // Credentials are invalid
            // invalid, and cancel the load.
            // completionHandler(.cancelAuthenticationChallenge, nil)
            Logger.w("Invalid credentials for host \(protectionSpace.host) " +
                     "and method \(protectionSpace.authenticationMethod)")
            return .invalidCredential
        }

        // let credential = URLCredential(trust: serverTrust)
        // completionHandler(.useCredential, credential)
        return .success
    }

    private func checkValidity(of secTrust: SecTrust, protectionSpace: URLProtectionSpace) -> CredentialValidationResult {

        // Check if we have pins for the domain
        let host = protectionSpace.host
        let domainPins = pinsFor(domain: host)
        if domainPins.count == 0 {
            return .noPinsForDomain
        }

        // Before original trust object
        if !isValidSecurityChain(secTrust, host: host) {
            return .invalidChain
        }

        // Chain is valid, continue to
        let certficateCount = chainLenght(secTrust)

        for index in 0..<certficateCount {
            guard let certificate = certificate(at: index, from: secTrust) else {
                // This should not happen. Only if something went really wrong
                Logger.v("Something went wrong when validating certificate chain")
                return .error
            }

            guard let spki = spki(from: certificate) else {
                return .spkiError
            }

            if isPinned(spki: spki, pins: domainPins) {
                return .success
            }
        }
        return .invalidCertificate
    }

    private func isPinned(spki: CertSpki, pins: [CredentialPin]) -> Bool {
        return pins.filter { $0.hash == spki.hash }.count > 0
    }

    private func pinsFor(domain: String) -> [CredentialPin] {
        // TODO: Implement also using wildcards
        return pins.filter { $0.host == domain }
    }

    // Geting Subject Public Key Info (SPKI)
    func spki(from certificate: SecCertificate) -> CertSpki? {
        // TODO: This whole operation is expensive, create a hash cache
        // Extract and hash public key
        if var pKey = publicKey(from: certificate) {
            Logger.v("PublicKey Data: \n\(pKey.data.hexadecimalRepresentation)")
            // TODO: Check other algos
            // Compute the SPKI hash
            guard let keyHeader = PublicKeyHeaders.header(forType: pKey.type) else {
                // Being a supported header, this should not happen
                Logger.v("Couldn't find hexa header for public key type: \(pKey.type)")
                return nil
            }
            pKey.addHeader(keyHeader)
            return pKey
        }
        return nil
    }

    private func publicKey(from certificate: SecCertificate) -> CertSpki? {
        // Extract the public key from the server's certificate
        if let publicKey = SecCertificateCopyKey(certificate) {
            let keyType = typeOf(key: publicKey)
            if keyType.isSupported(),
               let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? {
                Logger.v("Plain PublicKey Data: \(publicKeyData.hexadecimalRepresentation)")
                return CertSpki(type: keyType, data: publicKeyData)
            }
        }
        return nil
    }

    private func base64Encoded(_ data: Data) -> Data? {
        return data.base64EncodedString().dataBytes
    }

    private func computeHash(_ data: Data, algo: KeyHashAlgo) -> Data? {
        switch algo {
        case .sha1:
            return hashSha1(data)
        case .sha256:
            return hashSha256(data)
        }
    }

    private func hashSha256(_ data: Data) -> Data? {
        var sha256 = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &sha256)
        }
        return Data(sha256)
    }

    private func hashSha1(_ data: Data) -> Data? {
        var sha1 = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &sha1)
        }
        return Data(sha1)
    }

    private func isValidSecurityChain(_ secTrust: SecTrust, host: String) -> Bool {
        var evalError: UnsafeMutablePointer<CFError?>?

        // Creating a default SSL policy
        let policy = SecPolicyCreateSSL(true, host as CFString)
        SecTrustSetPolicies(secTrust, policy)
        let result = SecTrustEvaluateWithError(secTrust, evalError)

        if let error = evalError {
            // If there's an error, check what is it about and log result
            Logger.e("Error evaluating TLS Certificate: \(error.pointee?.localizedDescription ?? "Unknown")")

            // Get more details about the error while evaluating
            var resultType = UnsafeMutablePointer<SecTrustResultType>.allocate(capacity: MemoryLayout<Int>.size)
            let status = SecTrustGetTrustResult(secTrust, resultType)

            // Get readable message
            let message = SecCopyErrorMessageString(status, nil) as? String
            Logger.v("Validation chain failed: \(message ?? "Unknown")")
        }
        return result
    }

    private func certificate(at index: Int, from secTrust: SecTrust) -> SecCertificate? {
        if #available(iOS 15.0, *) {
            guard let certs = SecTrustCopyCertificateChain(secTrust) as? [SecCertificate] else { return nil }
            // Double checking just in case
            if certs.count > index {
                return certs[index]
            }
        } else {
            // SecTrustGetCertificateCount is deprecated, so using only for iOS < 15
            // Double checking just in case
            if chainLenght(secTrust) > index {
                return SecTrustGetCertificateAtIndex(secTrust, index)
            }
        }
        return nil
    }

    private func typeOf(key: SecKey) -> CertKeyType {

        let keyInfo = SecKeyCopyAttributes(key) as? [String: AnyObject]

//        print("Key Info: \(keyInfo ?? [:])")
        if let keyInfo = keyInfo,
           let type = keyInfo[kSecAttrKeyType as String] as? String,
           let size = keyInfo[kSecAttrKeySizeInBits as String] as? Int {
            Logger.v("Getting key type: \(type):\(size)")
            return CertKeyType.from(type: type, size: size)
        }
        return .unsupported
    }

    private func chainLenght(_ secTrust: SecTrust) -> Int {
        return SecTrustGetCertificateCount(secTrust)
    }

    private func logValidationAvoidance(host: String, method: String, message: String) {
        Logger.d("Skipping validation for host \(host) and method \(method): \(message)")
    }
}
