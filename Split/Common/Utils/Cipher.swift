//
//  Cipher.swift
//  Split
//
//  Created by Javier Avrudsky on 06-Mar-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import CommonCrypto
import Foundation

protocol KeyGenerator {
    func generateKey(size: Int) -> Data?
}

struct DefaultKeyGenerator: KeyGenerator {
    func generateKey(size: Int) -> Data? {
        let pointer: UnsafeMutablePointer<Int8> = UnsafeMutablePointer.allocate(capacity: size)
        defer { pointer.deallocate() }
        let status = SecRandomCopyBytes(kSecRandomDefault, size, pointer)

        if status == errSecSuccess { // Always test the status.
            return Data(bytes: pointer, count: size)
        }
        return nil
    }
}

protocol Cipher {
    func encrypt(_ text: String?) -> String?
    func decrypt(_ text: String?) -> String?
}

struct DefaultCipher: Cipher {
    private let cipherKey: Data

    init(cipherKey: Data) {
        self.cipherKey = cipherKey
    }

    func encrypt(_ text: String?) -> String? {
        if let text = text,
           let textBytes = text.data(using: .utf8) {
            return encryptAES128(data: textBytes, key: cipherKey)?.base64EncodedString(options: [])
        }
        return nil
    }

    func decrypt(_ text: String?) -> String? {
        if let text = text,
           let textBytes = Base64Utils.decodeBase64(text) {
            return decryptAES128(data: textBytes, key: cipherKey)?.stringRepresentation
        }
        return nil
    }

    private func encryptAES128(data: Data, key: Data) -> Data? {
        let cryptLength = size_t(data.count + kCCBlockSizeAES128)
        var cryptData = Data(count: cryptLength)

        var numBytesEncrypted: size_t = 0
        let options = CCOptions(kCCOptionPKCS7Padding)

        let status = cryptData.withUnsafeMutableBytes { (cryptBytes: UnsafeMutableRawBufferPointer) -> Int in
            var result: Int32 = -1
            data.withUnsafeBytes { (dataBytes: UnsafeRawBufferPointer) in
                key.withUnsafeBytes { (keyBytes: UnsafeRawBufferPointer) in
                    result = CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        options,
                        keyBytes.baseAddress,
                        key.count,
                        nil,
                        dataBytes.baseAddress,
                        data.count,
                        cryptBytes.baseAddress,
                        cryptLength,
                        &numBytesEncrypted)
                }
            }
            return Int(result)
        }

        guard status == kCCSuccess else {
            logError(status, operation: "encrypt")
            return nil
        }

        cryptData.removeSubrange(numBytesEncrypted ..< cryptData.count)

        return cryptData
    }

    private func decryptAES128(data: Data, key: Data) -> Data? {
        let cryptLength = size_t(data.count + kCCBlockSizeAES128)
        var cryptData = Data(count: cryptLength)

        var numBytesEncrypted: size_t = 0
        let options = CCOptions(kCCOptionPKCS7Padding)

        let status = cryptData.withUnsafeMutableBytes { (cryptBytes: UnsafeMutableRawBufferPointer) -> Int in
            var result: Int32 = -1
            data.withUnsafeBytes { (dataBytes: UnsafeRawBufferPointer) in
                key.withUnsafeBytes { (keyBytes: UnsafeRawBufferPointer) in
                    result = CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        options,
                        keyBytes.baseAddress,
                        key.count,
                        nil,
                        dataBytes.baseAddress,
                        data.count,
                        cryptBytes.baseAddress,
                        cryptLength,
                        &numBytesEncrypted)
                }
            }
            return Int(result)
        }
        guard status == kCCSuccess else {
            logError(status, operation: "decryp")
            return nil
        }

        cryptData.removeSubrange(numBytesEncrypted ..< cryptData.count)
        return cryptData
    }

    private let errors = [
        kCCParamError: "kCCParamError",
        kCCBufferTooSmall: "kCCBufferTooSmall",
        kCCMemoryFailure: "kCCMemoryFailure",
        kCCAlignmentError: "kCCAlignmentError",
        kCCDecodeError: "kCCDecodeError",
        kCCUnimplemented: "kCCUnimplemented",
        kCCOverflow: "kCCOverflow",
        kCCRNGFailure: "kCCRNGFailure",
        kCCUnspecifiedError: "kCCUnspecifiedError",
        kCCCallSequenceError: "kCCCallSequenceError",
        kCCKeySizeError: "kCCKeySizeError",
        kCCInvalidKey: "kCCInvalidKey",
    ]

    private func logError(_ status: Int, operation: String = "Enc") {
        Logger.v("Error when \(operation): \(errors[status] ?? "Unknown")")
    }

    private static func sanitizeKey(_ key: String) -> String {
        if key.count > ServiceConstants.aes128KeyLength {
            return String(key.prefix(ServiceConstants.aes128KeyLength))
        } else if key.count < ServiceConstants.aes128KeyLength {
            return "\(key)\(String(repeating: "0", count: ServiceConstants.aes128KeyLength - key.count))"
        }
        return key
    }
}
