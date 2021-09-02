//
//  CompressionUtil.swift
//  Split
//
//  Created by Javier Avrudsky on 01-Sep-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
import Compression

enum CompressionError: Error {
    case couldNotUncompressZlib
    case couldNotCompressToZlib
}

protocol CompressionUtil {
    func compress(_ data: Data) throws -> Data
    func decompress(_ data: Data) throws -> Data
}

struct Zlib: CompressionUtil {
    func compress(_ data: Data) throws -> Data {

        let dstBufferSize = 10 * 1024 // 10K
        let dstBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: dstBufferSize)

        let srcBufferSize = data.count
        let srcBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: srcBufferSize)
        data.copyBytes(to: srcBuffer, count: data.count)

        let compCount = compression_encode_buffer(dstBuffer, dstBufferSize, srcBuffer, srcBufferSize, nil, COMPRESSION_ZLIB)
        if compCount == 0 {
            throw CompressionError.couldNotCompressToZlib
        }

        var result = Data()
        result.append(dstBuffer, count: compCount)
        return result

    }

    func decompress(_ data: Data) throws -> Data {
        let dstBufferSize = data.count * 5
        let dstBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: dstBufferSize)

        let srcBufferSize = data.count
        let srcBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: srcBufferSize)
        data.copyBytes(to: srcBuffer, count: data.count)

        let compCount = compression_decode_buffer(dstBuffer, dstBufferSize, srcBuffer, srcBufferSize, nil, COMPRESSION_ZLIB)
        if compCount == 0 {
            throw CompressionError.couldNotUncompressZlib
        }

        var result = Data()
        result.append(dstBuffer, count: compCount)
        return result
    }

    func decomp(_ encodedSourceData: Data) throws -> String {
        let decodedCapacity = 8_000_000
        let decodedDestinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: decodedCapacity)
        let decodedString: String = encodedSourceData.withUnsafeBytes { encodedSourceBuffer in
            let typedPointer = encodedSourceBuffer.bindMemory(to: UInt8.self)
            let decodedCharCount = compression_decode_buffer(decodedDestinationBuffer, decodedCapacity,
                                                             typedPointer.baseAddress!, encodedSourceData.count,
                                                             nil,
                                                             COMPRESSION_ZLIB)

            print("Buffer decompressedCharCount", decodedCharCount)

            let str = String(cString: decodedDestinationBuffer)
            return String(cString: decodedDestinationBuffer)
        }
        return decodedString
    }
}
