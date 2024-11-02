//
//  MySegmentV2PayloadDecoder.swift
//  Split
//
//  Created by Javier Avrudsky on 14-Sep-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

enum NotificationPayloadParsingException: Error {
    case errorDecodingBase64
    case unknown
}

protocol SegmentsPayloadDecoder {

    func decodeAsString(payload: String, compressionUtil: CompressionUtil) throws -> String

    func decodeAsBytes(payload: String, compressionUtil: CompressionUtil) throws -> Data

    func hashKey(_ key: String) -> UInt64

    func parseKeyList(jsonString: String) throws -> KeyList

    func isKeyInBitmap(keyMap: Data, hashedKey: UInt64) -> Bool

    func computeKeyIndex(hashedKey: UInt64, keyMapLength: Int) -> Int

}

struct DefaultSegmentsPayloadDecoder: SegmentsPayloadDecoder {

    private let kFieldSize = 8

    func decodeAsString(payload: String, compressionUtil: CompressionUtil) throws -> String {
        return try decodeAsBytes(payload: payload, compressionUtil: compressionUtil).stringRepresentation
    }

    func decodeAsBytes(payload: String, compressionUtil: CompressionUtil) throws -> Data {
        guard let dec =  Base64Utils.decodeBase64(payload) else {
            throw NotificationPayloadParsingException.errorDecodingBase64
        }
        let descomp = try compressionUtil.decompress(data: dec)
        return descomp
    }

    func parseKeyList(jsonString: String) throws -> KeyList {
        return try Json.decodeFrom(json: jsonString, to: KeyList.self)
    }

    func hashKey(_ key: String) -> UInt64 {
        return Murmur64x128.hashKey(key)
    }

    func isKeyInBitmap(keyMap: Data, hashedKey: UInt64) -> Bool {
        let index = computeKeyIndex(hashedKey: hashedKey, keyMapLength: keyMap.count)
        let bit = index / kFieldSize
        let offset: UInt8 = UInt8(index % kFieldSize)
        if bit > keyMap.count - 1 {
            return false
        }
        return (keyMap[bit] & 1 << offset) != 0
    }

    func computeKeyIndex(hashedKey: UInt64, keyMapLength: Int) -> Int {
        return Int(hashedKey % UInt64(keyMapLength * kFieldSize))
    }
}
