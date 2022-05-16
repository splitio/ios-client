//
//  CompressionUtil.swift
//  Split
//
//  Created by Javier Avrudsky on 01-Sep-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
import Compression

enum CompressionType: Decodable {
    case none
    case gzip
    case zlib
    case unknown

    init(from decoder: Decoder) throws {
        let intValue = try? decoder.singleValueContainer().decode(Int.self)
        self = CompressionType.enumFromInt(intValue ?? 0)
    }

    static func enumFromInt(_ intValue: Int) -> CompressionType {
        switch intValue {
        case 0:
            return CompressionType.none
        case 1:
            return CompressionType.gzip
        case 2:
            return CompressionType.zlib
        default:
            return CompressionType.unknown
        }
    }
}

enum CompressionError: Error {
    case couldNotDecompressData
    case couldNotDecompressZlib
    case couldNotDecompressGzip
    case couldNotRemoveHeader
    case headerSizeError

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
        case .headerSizeError:
            return "Could not get header size"
        }
    }
}

protocol CompressionUtil {
    func decompress(data: Data) throws -> Data
}

private struct CompressionBase {
    static func decompress(data: Data) throws -> Data {
        //
        // A typical zlib compression ratios are on the order of 2:1 to 5:1.
        // But for data like the bitmap array received it could be 1032:1
        // https://zlib.net/zlib_tech.html (Maximum Compression Factor)
        //
        let ratio = 1032
        let dstBufferSize = data.count * ratio
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
        srcBuffer.deallocate()
        dstBuffer.deallocate()
        return result
    }

    // To make compression_decode_buffer to work it's necessary to remove the gzip/zlib header
    // Based on https://datatracker.ietf.org/doc/html/rfc1951
    static func removeHeader(type: CompressionType, from data: Data, headerSize: Int) -> Data {
        var mutableData = Data(data)
        mutableData.removeSubrange(0..<headerSize)
        return mutableData
    }
}

struct Zlib: CompressionUtil {
    let kZlibHeaderSize = 2
    let kDicSize = 4

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

    // Checks if the header is correct and returns the amounts of bytes to be removed
    // in order to make the deflate method to work
    // Returns -1 if something is wrong
    // Based on https://datatracker.ietf.org/doc/html/rfc1950
    func checkAndGetHeaderSize(data: Data) -> Int {
        var headerSize = kZlibHeaderSize

        // Checking compression method and info in byte 0
        if (0x7 & data[0]) != 8 {
            Logger.e("Incorrect compression method found while trying to decompress zlib data")
            return -1
        }

        // Cinfo
        if (data[0] >> 3) > 7 {
            Logger.e("Incorrect compression info found while trying to decompress zlib data")
            return -1
        }

        // FCHECK
        // The FCHECK value must be such that CMF and FLG, when viewed as
       // a 16-bit unsigned integer stored in MSB order (CMF*256 + FLG),
        // is a multiple of 31.
        if UInt16(0xf & data[1]) != UInt16(data[1] << 8 | data[0]) {
            Logger.e("Incorrect fcheck value found while trying to decompress zlib data")
            return -1
        }

        // Check for FDICT info
        // If set, dict info (bytes 2, 3, 4, 5) should be available
        if (data[1] & 0x20) != 0 {
            headerSize+=kDicSize
        }

        return headerSize
    }
}

struct Gzip: CompressionUtil {
    private let kGzipHeaderSize = 10
    private let kId1: UInt8 = 31 // 0xuf
    private let kId2 = 139 // 0x8b
    private let kCm: UInt8 = 8
    func decompress(data: Data) throws -> Data {

        let headerSize = checkAndGetHeaderSize(data: data)
        if headerSize == -1 {
            throw CompressionError.headerSizeError
        }

        let deflatedData = CompressionBase.removeHeader(type: .gzip,
                                                        from: data,
                                                        headerSize: headerSize)
        do {
            return try CompressionBase.decompress(data: deflatedData)
        } catch {
            throw CompressionError.couldNotDecompressGzip
        }
    }

    // Checks if the header is correct and returns the amounts of bytes to be removed
    // in order to make the deflate method to work
    // Returns -1 if something is wrong
    // Based on https://datatracker.ietf.org/doc/html/rfc1951
    func checkAndGetHeaderSize(data: Data) -> Int {

        if data.count < kGzipHeaderSize {
            return -1
        }

        // Checking ID1 y ID2
        // ID1 (IDentification 1)
        // ID2 (IDentification 2)
        // These have the fixed values ID1 = 31 (0x1f, \037), ID2 = 139
        // (0x8b, \213), to identify the file as being in gzip format.
        if data[0] != 0x1f || data[1] != 0x8b {
            Logger.e("Incorrect gzip header ID: 1=\(data[0]), 2=\(data[1])")
            return -1
        }

        // Checking compression method. It always be 8
        if data[2] != 8 {
            Logger.e("Incorrect gzip compression method: \(data[2])")
            return -1
        }

        // Checks passed, now checking total header size
        // Initial 10 bytes are fixed header
        var headerSize = kGzipHeaderSize

        let flg = data[3]

        // Extra field check, byte 3, bit 2
        if flg & (1 << 2) != 0 {
            // Check size to remove extra field
            // It's in little indian, so chante to big indian
            // Adding 4 bytes corresponding to the extra field header
            headerSize += (Int(data[12]) | Int(data[13] & 0xff) << 8) + 4
        }

        // File name. Should be 0 for curren usage, but just in case.
        // Byte 3, bit 3 (starting from 0)
        // This checks should be done before following checks so that we can
        // use current header size to count file name field size
        // because it's 0 terminated
        if flg & (1 << 3) != 0 {
            let range = Data(data[headerSize..<data.count])
            if let nameEnd = range.firstIndex(of: 0) {
                headerSize+=(nameEnd + 1)
            } else {
                Logger.e("Incorrect gzip format. File name end not present.")
                return -1
            }
        }

        // Comment. Should be 0 for curren usage, but just in case.
        // Byte 3, bit 4
        // This checks should be done before following checks so that we can
        // use current header size to count file name field size
        // because it's 0 terminated
        if flg & (1 << 4) != 0 {
            let range = Data(data[headerSize..<data.count])
            if let nameEnd = range.firstIndex(of: 0) {
                headerSize+=(nameEnd + 1)
            } else {
                Logger.e("Incorrect gzip format. Comment end not present.")
                return -1
            }
        }

        // Crc check, byte 3 , bit 1
        if flg & (1 << 1) != 0 {
            // crc info is 2 bytes
            headerSize+=2
        }

        return headerSize
    }
}
