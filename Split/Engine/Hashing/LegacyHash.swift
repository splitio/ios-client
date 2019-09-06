//
//  LegacyHash.swift
//  Split
//
//  Created by Natalia  Stele on 11/10/17.
//

import Foundation

// swiftlint:disable identifier_name
class LegacyHash {

    static func getHash(_ key: String, _ seed: Int32) -> Int64 {
        var h: Int32 = 0
        for character: Character in key {
            let value = Int32(truncatingIfNeeded: character.unicodeScalars.first!.value)
            let shifted = (h &* 31)
            h = shifted + value
        }
        return Int64(h ^ seed)
    }
}

extension Character {
    var asciiValue: UInt32? {
        return String(self).unicodeScalars.filter {$0.isASCII}.first?.value
    }
}
