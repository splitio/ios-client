//
//  MySegmentsV2PayloadDecoderMock.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 14-Sep-2021.
//  Copyright © 2021 Split. All rights reserved.
//
@testable import Split

import Foundation

class SegmentsPayloadDecoderMock: SegmentsPayloadDecoder {
    var hashedKey: UInt64 = 1
    var decodedString: String?
    var parsedKeyList: KeyList?
    var decodedBytes: Data?
    var keyMapResult = [Bool]()

    func decodeAsString(payload: String, compressionUtil: CompressionUtil) throws -> String {
        return decodedString ?? ""
    }

    func decodeAsBytes(payload: String, compressionUtil: CompressionUtil) throws -> Data {
        return decodedBytes ?? Data()
    }

    func hashKey(_ key: String) -> UInt64 {
        return hashedKey
    }

    func parseKeyList(jsonString: String) throws -> KeyList {
        if let list = parsedKeyList {
            return list
        }
        throw NotificationPayloadParsingException.unknown
    }

    func isKeyInBitmap(keyMap: Data, hashedKey: UInt64) -> Bool {
        let value = keyMapResult[0]
        keyMapResult.remove(at: 0)
        return value
    }

    func computeKeyIndex(hashedKey: UInt64, keyMapLength: Int) -> Int {
        return 1
    }
}
