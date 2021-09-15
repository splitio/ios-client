//
//  MySegmentV2PayloadDecoder.swift
//  Split
//
//  Created by Javier Avrudsky on 14-Sep-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

enum MySegmentsV2ParsingException: Error {
    case errorDecodingBase64
    case unknown
}

protocol MySegmentsV2PayloadDecoder {

    func decodeAsString(payload: String, compressionUtil: CompressionUtil) throws -> String

    func decodeAsBytes(payload: String, compressionUtil: CompressionUtil) throws -> Data

    func hashKey(_ key: String) -> UInt64

    func parseKeyList(jsonString: String) -> KeyList?

}

struct DefaultMySegmentsV2PayloadDecoder: MySegmentsV2PayloadDecoder {
    private let kFieldSize = 8

    func decodeAsString(payload: String, compressionUtil: CompressionUtil) throws -> String {
        return try decodeAsBytes(payload: payload, compressionUtil: compressionUtil).stringRepresentation
    }

    func decodeAsBytes(payload: String, compressionUtil: CompressionUtil) throws -> Data {
        guard let dec =  Base64Utils.decodeBase64(payload) else {
            throw MySegmentsV2ParsingException.errorDecodingBase64
        }
        let descomp = try compressionUtil.decompress(data: dec)
        return descomp
    }

    func parseKeyList(jsonString: String) -> KeyList? {
        do {
            return try Json.encodeFrom(json: jsonString, to: KeyList.self)
        } catch {
            Logger.e("Error parsing keyList: \(jsonString)")
        }
        return nil
    }

    func hashKey(_ key: String) -> UInt64 {
        return Murmur64x128.hash(data: Array(key.utf8), offset: 0, length: UInt32(key.count), seed: 0)[0]
    }
}
