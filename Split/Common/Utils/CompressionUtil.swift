//
//  CompressionUtil.swift
//  Split
//
//  Created by Javier Avrudsky on 01-Sep-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
import Compression

enum CompressionType {
    case zlib
    case gzip
}

enum CompressionError: Error {
    case couldNotDecompressData
    case couldNotDecompressZlib
    case couldNotDecompressGzip
    case couldNotRemoveHeader

    func message() -> String {
        switch self {
        case .couldNotRemoveHeader:
            return "Could not remove header"
        case .couldNotDecompressData:
            return "Could not decompress data"
        case .couldNotDecompressZlib:
            return "Could not decompress ZLIB data"
        case .couldNotDecompressGzip:
            return "Could not decompress GZIP data"
        }
    }
}

protocol CompressionUtil {
    func decompress(data: Data) throws -> Data
}

private struct CompressionBase {
    static func decompress(data: Data) throws -> Data {

        let dstBufferSize = data.count * 5
        let dstBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: dstBufferSize)

        let srcBufferSize = data.count
        let srcBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: srcBufferSize)
        data.copyBytes(to: srcBuffer, count: data.count)

        let compCount = compression_decode_buffer(dstBuffer, dstBufferSize, srcBuffer,
                                                  srcBufferSize, nil, COMPRESSION_ZLIB)
        if compCount == 0 {
            throw CompressionError.couldNotDecompressData
        }

        var result = Data()
        result.append(dstBuffer, count: compCount)
        return result
    }

    static func removeHeader(type: CompressionType, from data: Data, headerSize: Int) -> Data {
        var mutableData = Data(data)
        mutableData.removeSubrange(0..<headerSize)
        return mutableData
    }
}

struct Zlib: CompressionUtil {
    let kZlibHeaderSize = 2

    func decompress(data: Data) throws -> Data {

        let deflatedData = CompressionBase.removeHeader(type: .zlib,
                                                        from: data,
                                                        headerSize: kZlibHeaderSize)
        do {
            return try CompressionBase.decompress(data: deflatedData)
        } catch {
            throw CompressionError.couldNotDecompressZlib
        }
    }
}

struct Gzip: CompressionUtil {
    let kGzipHeaderSize = 5

    func decompress(data: Data) throws -> Data {

        let deflatedData = CompressionBase.removeHeader(type: .gzip,
                                                        from: data,
                                                        headerSize: kGzipHeaderSize)
        do {
            return try CompressionBase.decompress(data: deflatedData)
        } catch {
            throw CompressionError.couldNotDecompressGzip
        }
    }
}
