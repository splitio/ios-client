//
//  Murmur64x128.swift
//  Split
//
//  Created by Javier Avrudsky on 30-Aug-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

class Murmur64x128 {
    ///
    /// The following set of methods are based on `org.apache.commons.codec.digest.MurmurHash3`
    ///

    // swiftlint:disable identifier_name function_parameter_count function_body_length
    // Constants for 128-bit variant
    private static let c1: UInt64 = 0x87c37b91114253d5
    private static let c2: UInt64 = 0x4cf5ad432745937f
    private static let r1: UInt64 = 31
    private static let r2: UInt64 = 27
    private static let r3: UInt64 = 33
    private static let m: UInt64 = 5
    private static let n1: UInt64 = 0x52dce729
    private static let n2: UInt64 = 0x38495ab5

    ///
    /// Gets the little-endian long from 8 bytes starting at the specified index.
    ///
    /// @param data The data
    /// @param index The index
    /// @return The little-endian long
    ///
    private static func getLittleEndianLong(data: [UInt8], index: Int) -> UInt64 {
        var result = UInt64(data[index])
        result |= UInt64(data[index + 1] & 0xff) << 8
        result |= UInt64(data[index + 2] & 0xff) << 16
        result |= UInt64(data[index + 3] & 0xff) << 24
        result |= UInt64(data[index + 4] & 0xff) << 32
        result |= UInt64(data[index + 5] & 0xff) << 40
        result |= UInt64(data[index + 6] & 0xff) << 48
        result |= UInt64(data[index + 7] & 0xff) << 56
        return result
    }

    /**
     * Generates 128-bit hash from the byte array with the given offset, length and seed.
     *
     * <p>This is an implementation of the 128-bit hash function {@code MurmurHash3_x64_128}
     * originally from Austin Applyby's original MurmurHash3 {@code c++} code in SMHasher.</p>
     *
     * @param data The input byte array
     * @param offset The first element of array
     * @param length The length of array
     * @param seed The initial seed value
     * @return The 128-bit hash (2 longs)
     */
    static func hash(data: [UInt8], offset: Int32, length: UInt32, seed: UInt64) -> [UInt64] {
        var h1 = seed
        var h2 = seed
        let nblocks = Int32(length >> 4)

        body(h1: &h1, h2: &h2, data: data, offset: offset, length: length, seed: seed, nblocks: nblocks)
        tail(h1: &h1, h2: &h2, data: data, offset: offset, length: length, nblocks: nblocks)

        return final(h1: &h1, h2: &h2, length: length)
    }

    private static func body(h1: inout UInt64, h2: inout UInt64, data: [UInt8], offset: Int32,
                             length: UInt32, seed: UInt64, nblocks: Int32) {

        for i in 0..<nblocks {
            let index = offset + (i << 4)
            var k1 = getLittleEndianLong(data: data, index: Int(index))
            var k2 = getLittleEndianLong(data: data, index: Int(index) + 8)

            // mix functions for k1
            k1 &*= c1
            k1 = k1.rotateLeft(r1)
            k1 &*= c2
            h1 ^= k1
            h1 = h1.rotateLeft(r2)
            h1 &+= h2
            h1 = h1 &* m &+ n1

            // mix functions for k2
            k2 &*= c2
            k2 = k2.rotateLeft(r3)
            k2 &*= c1
            h2 ^= k2
            h2 = h2.rotateLeft(r1)
            h2 &+= h1
            h2 = h2 &* m &+ n2
        }
    }

    private static func tail(h1: inout UInt64, h2: inout UInt64, data: [UInt8], offset: Int32,
                             length: UInt32, nblocks: Int32) {
        var k1: UInt64 = 0
        var k2: UInt64 = 0
        let index: Int = Int(offset + (nblocks << 4))
        switch Int(offset) + Int(length) - index {
        case 15:
            k2 ^= (UInt64(data[index + 14]) & 0xff) << 48
            fallthrough

        case 14:
            k2 ^= (UInt64(data[index + 13]) & 0xff) << 40
            fallthrough

        case 13:
            k2 ^= (UInt64(data[index + 12]) & 0xff) << 32
            fallthrough

        case 12:
            k2 ^= (UInt64(data[index + 11]) & 0xff) << 24
            fallthrough

        case 11:
            k2 ^= (UInt64(data[index + 10]) & 0xff) << 16
            fallthrough

        case 10:
            k2 ^= (UInt64(data[index + 9]) & 0xff) << 8
            fallthrough

        case 9:
            k2 ^= UInt64(data[index + 8]) & 0xff
            k2 &*= c2
            k2 = k2.rotateLeft(r3)
            k2 &*= c1
            h2 ^= k2
            fallthrough

        case 8:
            k1 ^= (UInt64(data[index + 7]) & 0xff) << 56
            fallthrough

        case 7:
            k1 ^= (UInt64( data[index + 6]) & 0xff) << 48
            fallthrough

        case 6:
            k1 ^= (UInt64(data[index + 5]) & 0xff) << 40
            fallthrough

        case 5:
            k1 ^= (UInt64(data[index + 4]) & 0xff) << 32
            fallthrough

        case 4:
            k1 ^= (UInt64(data[index + 3]) & 0xff) << 24
            fallthrough

        case 3:
            k1 ^= (UInt64(data[index + 2]) & 0xff) << 16
            fallthrough

        case 2:
            k1 ^= (UInt64(data[index + 1]) & 0xff) << 8
            fallthrough

        case 1:
            k1 ^= UInt64(data[index]) & 0xff
            k1 &*= c1
            k1 = k1.rotateLeft(r1)
            k1 &*= c2
            h1 ^= k1

        default:
            Logger.w("Murmur64 - Option not available")
        }
    }

    private static func final(h1: inout UInt64, h2: inout UInt64, length: UInt32) -> [UInt64] {
        // finalization
        h1 ^= UInt64(length)
        h2 ^= UInt64(length)

        h1 &+= h2
        h2 &+= h1

        h1 = fmix64(h1)
        h2 = fmix64(h2)

        h1 &+= h2
        h2 &+= h1

        return [h1, h2]
    }

    private static func fmix64(_ k: UInt64) -> UInt64 {
        var res: UInt64 = k
        res ^= (res >> 33)
        res &*= 0xff51afd7ed558ccd
        res ^= res >> 33
        res &*= 0xc4ceb9fe1a85ec53
        res ^= res >> 33
        return res
    }
}
