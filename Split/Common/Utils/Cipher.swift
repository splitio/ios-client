//
//  Cipher.swift
//  Split
//
//  Created by Javier Avrudsky on 06-Mar-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation
import CommonCrypto

protocol Cipher {
    func encrypt(_ text: String?) -> String?
    func decrypt(_ text: String?) -> String?
}

struct DefaultCipher: Cipher {

    private let keyBytes: Data

    init(key: String) {
        keyBytes = key.data(using: .utf8) ?? Data()
    }

    func encrypt(_ text: String?) -> String? {
            if let text = text,
               let textBytes = text.data(using: .utf8) {
                return encryptAES256(data: textBytes, key: keyBytes)?.base64EncodedString(options: [])
            }
            return nil
        }

        func decrypt(_ text: String?) -> String? {
            if let text = text,
               let textBytes = Base64Utils.decodeBase64(text) {
                return decryptAES256(data: textBytes, key: keyBytes)?.stringRepresentation
            }
            return nil
        }

    private func encryptAES256(data: Data, key: Data) -> Data? {
        let cryptLength = size_t(data.count + kCCBlockSizeAES128)
        var cryptData = Data(count: cryptLength)

        var numBytesEncrypted: size_t = 0
        let options = CCOptions(kCCOptionPKCS7Padding)

        let status = cryptData.withUnsafeMutableBytes { (cryptBytes: UnsafeMutableRawBufferPointer) -> Int in
            var result: Int32 = -1
            data.withUnsafeBytes { (dataBytes: UnsafeRawBufferPointer) -> Void in
                key.withUnsafeBytes { (keyBytes: UnsafeRawBufferPointer) -> Void in
                    result = CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmAES), options,
                                     keyBytes.baseAddress, key.count, nil, dataBytes.baseAddress,
                                     data.count, cryptBytes.baseAddress, cryptLength, &numBytesEncrypted)
                }
            }
            return Int(result)
        }

        guard status == kCCSuccess else {
            logError(status, operation: "encrypt")
            return nil
        }

        cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)

        return cryptData
    }

    private func decryptAES256(data: Data, key: Data) -> Data? {
        let cryptLength = size_t(data.count + kCCBlockSizeAES128)
        var cryptData = Data(count: cryptLength)

        var numBytesEncrypted: size_t = 0
        let options = CCOptions(kCCOptionPKCS7Padding)

        let status = cryptData.withUnsafeMutableBytes { (cryptBytes: UnsafeMutableRawBufferPointer) -> Int in
            var result: Int32 = -1
            data.withUnsafeBytes { (dataBytes: UnsafeRawBufferPointer) -> Void in
                key.withUnsafeBytes { (keyBytes: UnsafeRawBufferPointer) -> Void  in
                    result = CCCrypt(CCOperation(kCCDecrypt),
                                     CCAlgorithm(kCCAlgorithmAES),
                                     options, keyBytes.baseAddress, key.count, nil,
                                     dataBytes.baseAddress, data.count,
                                     cryptBytes.baseAddress, cryptLength, &numBytesEncrypted)
                }
            }
            return Int(result)
        }
        guard status == kCCSuccess else {
            logError(status, operation: "decryp")
            return nil
        }

        cryptData.removeSubrange(numBytesEncrypted..<cryptData.count)
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
        kCCInvalidKey: "kCCInvalidKey"]

    private func logError(_ status: Int, operation: String = "Enc") {
        Logger.v("Error when \(operation): \(errors[status] ?? "Unknown")")
    }
}
