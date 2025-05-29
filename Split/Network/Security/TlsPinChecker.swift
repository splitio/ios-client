//
//  SslPinValidator.swift
//  Split
//
//  Created by Javier Avrudsky on 05/06/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import CommonCrypto
import Foundation

enum PinType {
    case key
    case certificate
}

struct CredentialPin: Codable {
    let host: String
    let hash: Data
    let algo: KeyHashAlgo
}

enum CredentialValidationResult: CaseIterable {
    case success
    case error
    case noPinsForDomain
    case invalidChain
    case credentialNotPinned
    case spkiError
    case noServerTrustMethod
    case unavailableServerTrust
    case invalidCredential
    case invalidParameter

    var description: String {
        switch self {
        case .success:
            return "success"
        case .error:
            return "Error validating credentials"
        case .noPinsForDomain:
            return "No pins found for domain"
        case .invalidChain:
            return "Key chain invalided"
        case .credentialNotPinned:
            return "Credential is not pinned"
        case .spkiError:
            return "Unable to get SPKI from public key"
        case .noServerTrustMethod:
            return "Validation method is not Server Trust"
        case .unavailableServerTrust:
            return "No server trust available"
        case .invalidCredential:
            return "Invalid credentials"
        case .invalidParameter:
            return "Incorrect credentials type"
        }
    }
}

enum KeyHashAlgo: String, Codable {
    case sha256
    case sha1
}

enum CertKeyTypeHelper {
    private static let keyMapping: [String: CertKeyType] = [
        "\(kSecAttrKeyTypeRSA)_2048": .rsa2048,
        "\(kSecAttrKeyTypeRSA)_3072": .rsa3072,
        "\(kSecAttrKeyTypeRSA)_4096": .rsa4096,
        "\(kSecAttrKeyTypeEC)_256": .secp256r1,
        "\(kSecAttrKeyTypeEC)_384": .secp384r1,
        "\(kSecAttrKeyTypeEC)_521": .secp521r1,
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

protocol TlsPinChecker {
    func check(credential: AnyObject) -> CredentialValidationResult
}

struct DefaultTlsPinChecker: TlsPinChecker {
    private let pins: [CredentialPin]

    init(pins: [CredentialPin]) {
        self.pins = pins
    }

    // Using a generic parameter to aisolate Apple's framework and
    // also to make the component easily mockable
    func check(credential: AnyObject) -> CredentialValidationResult {
        guard let challenge = credential as? URLAuthenticationChallenge else {
            Logger.e("The credential received is not a URLAuthenticationChallenge")
            return .invalidParameter
        }

        // Checking that the authentication method is server trust
        // and that the host is pinned to validation
        let protectionSpace = challenge.protectionSpace
        if protectionSpace.authenticationMethod != NSURLAuthenticationMethodServerTrust {
            logValidationAvoidance(
                host: protectionSpace.host,
                method: protectionSpace.authenticationMethod,
                message: "No server trust")
            return .noServerTrustMethod
        }

        guard let serverTrust = protectionSpace.serverTrust else {
            logValidationAvoidance(
                host: protectionSpace.host,
                method: protectionSpace.authenticationMethod,
                message: "No server trust info")
            return .unavailableServerTrust
        }

        let result = checkValidity(of: serverTrust, protectionSpace: protectionSpace)
        Logger.d(
            "Credential validation result for host \(protectionSpace.host) " +
                "and method \(protectionSpace.authenticationMethod): \(result.description)")
        return result
    }

    private func checkValidity(
        of secTrust: SecTrust,
        protectionSpace: URLProtectionSpace) -> CredentialValidationResult {
        // Check if we have pins for the domain
        let host = protectionSpace.host
        let domainPins = pinsFor(domain: host, pins: pins)
        if domainPins.isEmpty {
            return .noPinsForDomain
        }

        // Before original trust object
        if !isValidSecurityChain(secTrust, host: host) {
            return .invalidChain
        }

        // Chain is valid, continue to
        let certficateCount = chainLength(secTrust)

        for index in 0 ..< certficateCount {
            guard let certificate = certificate(at: index, from: secTrust) else {
                // This should not happen. Only if something went really wrong
                Logger.e("Something went wrong when validating certificate chain")
                return .error
            }

            guard let spki = TlsCertificateParser.spki(from: certificate) else {
                return .spkiError
            }

            if isPinned(spki: spki, pins: domainPins) {
                return .success
            }
        }
        return .credentialNotPinned
    }

    private func isPinned(spki: CertSpki, pins: [CredentialPin]) -> Bool {
        // Cache to avoid hashing more than one time
        var hashCache = [KeyHashAlgo: Data]()
        for pin in pins {
            let hash = hashCache[pin.algo] ?? AlgoHelper.computeHash(spki.data, algo: pin.algo)
            // This check is to avoid decoding if not verbose level
            if Logger.shared.level == .verbose {
                Logger.v("Checking pinned \(pin.hash.base64EncodedString()) vs \(hash.base64EncodedString())")
            }
            if hash == pin.hash {
                return true
            }
            hashCache[pin.algo] = hash
        }
        return false
    }

    private func pinsFor(domain: String, pins: [CredentialPin]) -> [CredentialPin] {
        return HostDomainFilter.pinsFor(host: domain, pins: pins)
    }

    private func base64Encoded(_ data: Data) -> Data? {
        return data.base64EncodedString().dataBytes
    }

    private func isValidSecurityChain(_ secTrust: SecTrust, host: String) -> Bool {
        if #available(macOSApplicationExtension 10.14, macOS 10.14, *) {
            var evalError: CFError?

            // Creating a default SSL policy
            let policy = SecPolicyCreateSSL(true, host as CFString)
            SecTrustSetPolicies(secTrust, policy)
            let result = SecTrustEvaluateWithError(secTrust, &evalError)
            if let err = evalError {
                // If there's an error, check what is it about and log result
                Logger.e("Error evaluating TLS Certificate: \(err.localizedDescription)")

                // Get more details about the error while evaluating
                let resultType = UnsafeMutablePointer<SecTrustResultType>.allocate(capacity: MemoryLayout<Int>.size)
                let status = SecTrustGetTrustResult(secTrust, resultType)

                // Get readable message
                let message = SecCopyErrorMessageString(status, nil) as? String
                Logger.d("Validation chain failed: \(message ?? "Unknown")")
            }
            return result
        }
        return false
    }

    private func certificate(at index: Int, from secTrust: SecTrust) -> SecCertificate? {
        if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
            guard let certs = SecTrustCopyCertificateChain(secTrust) as? [SecCertificate] else { return nil }
            // Double checking just in case
            if certs.count > index {
                return certs[index]
            }
        } else {
            // SecTrustGetCertificateCount is deprecated, so using only for iOS < 15
            // Double checking just in case
            if chainLength(secTrust) > index {
                return SecTrustGetCertificateAtIndex(secTrust, index)
            }
        }
        return nil
    }

    private func chainLength(_ secTrust: SecTrust) -> Int {
        return SecTrustGetCertificateCount(secTrust)
    }

    private func logValidationAvoidance(host: String, method: String, message: String) {
        Logger.d("Skipping validation for host \(host) and method \(method): \(message)")
    }
}

enum AlgoHelper {
    static func computeHash(_ data: Data, algo: KeyHashAlgo) -> Data {
        switch algo {
        case .sha1:
            return hashSha1(data)
        case .sha256:
            return hashSha256(data)
        }
    }

    private static func hashSha256(_ data: Data) -> Data {
        var sha256 = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &sha256)
        }
        return Data(sha256)
    }

    private static func hashSha1(_ data: Data) -> Data {
        var sha1 = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &sha1)
        }
        return Data(sha1)
    }
}

// TODO: improve this parser to encapsulate Apple's framework
enum TlsCertificateParser {
    private static let certificateExtension = "der"
    static func spki(from certificateName: String, bundle: Bundle) -> CertSpki? {
        guard let certificate = loadCertificate(name: certificateName, bundle: bundle) else {
            Logger.e("Could not load certificate \(certificateName) to get SPKI")
            return nil
        }
        return spki(from: certificate)
    }

    private static func loadCertificate(name: String, bundle: Bundle) -> SecCertificate? {
        let loadedData = FileUtil.loadFileData(name: name, type: certificateExtension, bundle: bundle)
        guard let cerData = loadedData as? NSData else {
            Logger.e("Could not load certificate \(name) for name")
            return nil
        }

        return SecCertificateCreateWithData(nil, cerData)
    }

    // Geting Subject Public Key Info (SPKI)
    // This is visible for testing purposes, because this logic is simple but has a tricky implementation
    // It is not part of the implemented protocol
    static func spki(from certificate: SecCertificate) -> CertSpki? {
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

    static private func publicKey(from certificate: SecCertificate) -> CertSpki? {
        // Extract the public key from the server's certificate
        if #available(macOSApplicationExtension 10.14, macOS 10.14, *) {
            if let publicKey = SecCertificateCopyKey(certificate) {
                let keyType = typeOf(key: publicKey)
                if keyType.isSupported(),
                   let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? {
                    Logger.v("Plain PublicKey Data: \(publicKeyData.hexadecimalRepresentation)")
                    return CertSpki(type: keyType, data: publicKeyData)
                }
            }
        }
        return nil
    }

    static private func typeOf(key: SecKey) -> CertKeyType {
        let keyInfo = SecKeyCopyAttributes(key) as? [String: AnyObject]
        if let keyInfo = keyInfo,
           let type = keyInfo[kSecAttrKeyType as String] as? String,
           let size = keyInfo[kSecAttrKeySizeInBits as String] as? Int {
            Logger.v("Getting key type: \(type):\(size)")
            return CertKeyType.from(type: type, size: size)
        }
        return .unsupported
    }
}
